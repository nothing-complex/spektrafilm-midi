#include "SpektraMidiControl.h"

#if defined(_WIN32)
#  ifndef WIN32_LEAN_AND_MEAN
#    define WIN32_LEAN_AND_MEAN
#  endif
#  ifndef NOMINMAX
#    define NOMINMAX
#  endif
#  include <winsock2.h>
#  include <ws2tcpip.h>
#else
#  include <arpa/inet.h>
#  include <sys/socket.h>
#  include <sys/select.h>
#  include <unistd.h>
#endif

#include <algorithm>
#include <atomic>
#include <charconv>
#include <chrono>
#include <cmath>
#include <cstdlib>
#include <deque>
#include <iomanip>
#include <limits>
#include <locale>
#include <mutex>
#include <random>
#include <sstream>
#include <thread>

namespace spektrafilm::midi {
namespace {
constexpr std::size_t kMaximumPacket = 8192;
constexpr std::size_t kMaximumPending = 2048;
constexpr auto kMaximumQueueAge = std::chrono::seconds(2);
constexpr auto kCompanionTimeout = std::chrono::seconds(3);
using Clock = std::chrono::steady_clock;
#if defined(_WIN32)
using Socket = SOCKET;
constexpr Socket kInvalidSocket = INVALID_SOCKET;
void closeSocket(Socket socket) { closesocket(socket); }
#else
using Socket = int;
constexpr Socket kInvalidSocket = -1;
void closeSocket(Socket socket) { close(socket); }
#endif

std::vector<std::string> split(const std::string &text) {
  std::vector<std::string> fields;
  std::size_t start = 0;
  do {
    const auto end = text.find('\t', start);
    fields.push_back(text.substr(start, end == std::string::npos ? end : end - start));
    if (end == std::string::npos) break;
    start = end + 1;
  } while (true);
  return fields;
}

template<typename T> bool integer(const std::string &text, T &number) {
  if (text.empty()) return false;
  const auto result = std::from_chars(text.data(), text.data() + text.size(), number);
  return result.ec == std::errc() && result.ptr == text.data() + text.size();
}

bool real(const std::string &text, double &number) {
  std::istringstream input(text);
  input.imbue(std::locale::classic());
  input >> std::noskipws >> number;
  return input && input.eof() && std::isfinite(number);
}

std::string numeric(double value) {
  std::ostringstream out;
  out.imbue(std::locale::classic());
  out << std::setprecision(std::numeric_limits<double>::max_digits10) << value;
  return out.str();
}

std::string token() {
  std::random_device random;
  std::ostringstream out;
  out << std::hex << std::setfill('0');
  for (int i = 0; i < 4; ++i) out << std::setw(8) << random();
  return out.str();
}

std::uint16_t companionPort() {
  const char *configured = std::getenv("TANGENT_MIDI_COMPANION_PORT");
  unsigned int port = 0;
  return configured && integer(std::string(configured), port) && port > 1023 && port <= 65535
    ? static_cast<std::uint16_t>(port) : 55051;
}
} // namespace

std::string percentEncode(const std::string &value) {
  constexpr char hex[] = "0123456789ABCDEF";
  std::string encoded;
  for (const unsigned char c : value) {
    if (c >= 32 && c < 127 && c != '%') encoded.push_back(static_cast<char>(c));
    else {
      encoded.push_back('%');
      encoded.push_back(hex[c >> 4]);
      encoded.push_back(hex[c & 15]);
    }
  }
  return encoded;
}

bool percentDecode(const std::string &value, std::string &decoded) {
  auto nibble = [](char c) -> int {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
  };
  decoded.clear();
  for (std::size_t i = 0; i < value.size(); ++i) {
    unsigned char c = static_cast<unsigned char>(value[i]);
    if (c == '%') {
      if (i + 2 >= value.size()) return false;
      const int high = nibble(value[i + 1]), low = nibble(value[i + 2]);
      if (high < 0 || low < 0) return false;
      c = static_cast<unsigned char>((high << 4) | low);
      i += 2;
    }
    if (c == 0) return false;
    decoded.push_back(static_cast<char>(c));
  }
  return true;
}

bool parseCommand(const std::string &packet, const std::string &session,
                  const std::string &instance, std::uint64_t generation,
                  Command &command, std::string &error) {
  error.clear();
  if (packet.size() > kMaximumPacket || packet.find('\0') != std::string::npos) {
    error = "BAD_PACKET"; return false;
  }
  const auto fields = split(packet);
  const bool reset = !fields.empty() && fields[0] == "RESET";
  if (fields.size() != (reset ? 7u : 8u) ||
      (fields[0] != "DELTA" && fields[0] != "SET" && !reset) || fields[1] != "1") {
    error = "BAD_COMMAND"; return false;
  }
  std::uint64_t targetGeneration = 0;
  if (fields[2] != session || fields[3] != instance ||
      !integer(fields[4], targetGeneration) || targetGeneration != generation) {
    error = "STALE_TARGET"; return false;
  }
  if (!percentDecode(fields[5], command.parameter) || command.parameter.empty() ||
      command.parameter.size() > 128 || !integer(fields[6], command.component) ||
      command.component < 0 || command.component > 2 || (!reset && !real(fields[7], command.value))) {
    error = "BAD_VALUE"; return false;
  }
  command.operation = reset ? Operation::Reset : fields[0] == "SET" ? Operation::Set : Operation::Delta;
  command.generation = targetGeneration;
  if (reset) command.value = 0;
  return true;
}

class Endpoint {
public:
  std::string id = token();
  std::string label;
  std::uint64_t generation = 1;
  std::uint64_t revision = 0;
  bool armed = false;
  bool snapshotDirty = true;
  bool present = true;
  Clock::time_point lastContact = Clock::now();
  std::vector<Parameter> parameters;
  struct Pending { Command command; Clock::time_point received; };
  std::deque<Pending> pending;
};

struct Broker::Impl {
  mutable std::mutex mutex;
  std::mutex lifecycleMutex;
  std::string session = token();
  std::vector<std::shared_ptr<Endpoint>> endpoints;
  Socket socket = kInvalidSocket;
  std::uint16_t port = 0;
  std::uint16_t destinationPort = companionPort();
  std::atomic<bool> running{false};
  std::thread worker;
#if defined(_WIN32)
  bool winsockStarted = false;
#endif

  std::string prefix(const Endpoint &endpoint) const {
    return "1\t" + session + "\t" + endpoint.id + "\t" + std::to_string(endpoint.generation);
  }

  void send(const std::string &packet) const {
    if (socket == kInvalidSocket || packet.size() > 65507) return;
    sockaddr_in destination{};
    destination.sin_family = AF_INET;
    destination.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    destination.sin_port = htons(destinationPort);
    sendto(socket, packet.data(), static_cast<int>(packet.size()), 0,
           reinterpret_cast<const sockaddr *>(&destination), sizeof(destination));
  }

  void reply(const Endpoint &endpoint, bool error, const std::string &operation,
             const std::string &status, const std::string &detail = {}) const {
    send((error ? "ERROR\t" : "ACK\t") + prefix(endpoint) + "\t" + operation + "\t" +
         status + "\t" + percentEncode(detail));
  }

  void advertise(const Endpoint &endpoint) const {
    send("INSTANCE\t" + prefix(endpoint) + "\t" + std::to_string(port) + "\t" +
         (endpoint.armed ? "1" : "0") + "\t" + std::to_string(endpoint.revision) + "\t" + percentEncode(endpoint.label));
  }

  void snapshot(const Endpoint &endpoint) const {
    const std::string base = prefix(endpoint) + "\t" + std::to_string(endpoint.revision);
    send("STATE_BEGIN\t" + base + "\t" + std::to_string(endpoint.parameters.size()));
    for (const auto &param : endpoint.parameters) {
      send("PARAM\t" + base + "\t" + percentEncode(param.id) + "\t" + param.type + "\t" +
           std::to_string(param.component) + "\t" + numeric(param.minimum) + "\t" + numeric(param.maximum) + "\t" +
           numeric(param.step) + "\t" + numeric(param.defaultValue) + "\t" + numeric(param.value) + "\t" +
           (param.available ? "1" : "0") + "\t" + percentEncode(param.label) + "\t" + percentEncode(param.choices));
    }
    send("STATE_END\t" + base);
  }

  void invalidate(Endpoint &endpoint) {
    endpoint.armed = false;
    ++endpoint.generation;
    endpoint.pending.clear();
    endpoint.snapshotDirty = true;
  }

  void receive(const std::string &packet) {
    const auto fields = split(packet);
    if (fields.size() < 5 || fields[1] != "1" || fields[2] != session) return;
    std::lock_guard<std::mutex> lock(mutex);
    const auto found = std::find_if(endpoints.begin(), endpoints.end(), [&](const auto &entry) { return entry->id == fields[3]; });
    if (found == endpoints.end()) return;
    auto &endpoint = **found;
    std::uint64_t generation = 0;
    if (!integer(fields[4], generation) || generation != endpoint.generation) {
      reply(endpoint, true, fields[0], "STALE_TARGET"); return;
    }
    endpoint.lastContact = Clock::now();
    if (fields[0] == "SNAPSHOT" && fields.size() == 5) {
      endpoint.snapshotDirty = true;
      return;
    }
    if (fields[0] == "DISARM" && fields.size() == 5) {
      invalidate(endpoint);
      reply(endpoint, false, fields[0], "DISARMED");
      advertise(endpoint);
      return;
    }
    if (!endpoint.armed) { reply(endpoint, true, fields[0], "NOT_ARMED"); return; }
    if (fields[0] == "APPLY" && fields.size() == 5) {
      reply(endpoint, false, fields[0], "PENDING_HOST_ACTION", "Invoke the visible Apply MIDI button in the host.");
      return;
    }
    Command command;
    std::string error;
    if (!parseCommand(packet, session, endpoint.id, endpoint.generation, command, error)) {
      reply(endpoint, true, fields[0], error); return;
    }
    const auto parameter = std::find_if(endpoint.parameters.begin(), endpoint.parameters.end(), [&](const auto &param) {
      return param.id == command.parameter && param.component == command.component;
    });
    if (parameter == endpoint.parameters.end()) { reply(endpoint, true, fields[0], "UNKNOWN_PARAMETER"); return; }
    if (!parameter->available) { reply(endpoint, true, fields[0], "UNAVAILABLE_PARAMETER"); return; }
    if (endpoint.pending.size() >= kMaximumPending) {
      invalidate(endpoint);
      reply(endpoint, true, fields[0], "QUEUE_OVERFLOW", "Target disarmed; no queued movement was applied.");
      return;
    }
    endpoint.pending.push_back({std::move(command), Clock::now()});
    reply(endpoint, false, fields[0], "QUEUED");
  }

  void loop() {
    auto lastAdvertisement = Clock::time_point{};
    while (running.load()) {
      fd_set readSet;
      FD_ZERO(&readSet);
      FD_SET(socket, &readSet);
      timeval timeout{0, 100000};
      if (select(static_cast<int>(socket + 1), &readSet, nullptr, nullptr, &timeout) > 0) {
        char buffer[kMaximumPacket + 1];
        sockaddr_in source{};
#if defined(_WIN32)
        int sourceSize = sizeof(source);
#else
        socklen_t sourceSize = sizeof(source);
#endif
        const int count = static_cast<int>(recvfrom(socket, buffer, sizeof(buffer), 0,
          reinterpret_cast<sockaddr *>(&source), &sourceSize));
        if (count > 0 && count <= static_cast<int>(kMaximumPacket) &&
            source.sin_addr.s_addr == htonl(INADDR_LOOPBACK) && ntohs(source.sin_port) == destinationPort) {
          receive(std::string(buffer, static_cast<std::size_t>(count)));
        }
      }
      const auto now = Clock::now();
      std::lock_guard<std::mutex> lock(mutex);
      const bool advertiseNow = now - lastAdvertisement >= std::chrono::seconds(1);
      for (const auto &endpoint : endpoints) {
        if (endpoint->armed && now - endpoint->lastContact > kCompanionTimeout) {
          invalidate(*endpoint);
          reply(*endpoint, true, "TARGET", "COMPANION_TIMEOUT", "Target disarmed; queued movement discarded.");
        }
        if (advertiseNow) advertise(*endpoint);
        if (endpoint->snapshotDirty) {
          advertise(*endpoint);
          snapshot(*endpoint);
          endpoint->snapshotDirty = false;
        }
      }
      if (advertiseNow) lastAdvertisement = now;
    }
  }

  bool start() {
    if (running.load()) return true;
#if defined(_WIN32)
    WSADATA data{};
    if (WSAStartup(MAKEWORD(2, 2), &data) != 0) return false;
    winsockStarted = true;
#endif
    socket = ::socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    sockaddr_in local{};
    local.sin_family = AF_INET;
    local.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    local.sin_port = 0;
    if (socket == kInvalidSocket || bind(socket, reinterpret_cast<const sockaddr *>(&local), sizeof(local)) != 0) {
      stop(); return false;
    }
#if defined(_WIN32)
    int size = sizeof(local);
#else
    socklen_t size = sizeof(local);
#endif
    if (getsockname(socket, reinterpret_cast<sockaddr *>(&local), &size) != 0) { stop(); return false; }
    port = ntohs(local.sin_port);
    running.store(true);
    worker = std::thread([this] { loop(); });
    return true;
  }

  void stop() {
    running.store(false);
    if (worker.joinable()) worker.join();
    if (socket != kInvalidSocket) { closeSocket(socket); socket = kInvalidSocket; }
#if defined(_WIN32)
    if (winsockStarted) { WSACleanup(); winsockStarted = false; }
#endif
  }
};

Broker::Broker() : impl_(std::make_unique<Impl>()) {}
Broker::~Broker() { shutdown(); }
Broker &Broker::instance() { static Broker broker; return broker; }

std::shared_ptr<Endpoint> Broker::registerInstance(const std::string &label) {
  std::lock_guard<std::mutex> lifecycleLock(impl_->lifecycleMutex);
  if (!impl_->start()) return {};
  auto endpoint = std::make_shared<Endpoint>();
  endpoint->label = label + " [" + endpoint->id.substr(0, 6) + "]";
  std::lock_guard<std::mutex> lock(impl_->mutex);
  impl_->endpoints.push_back(endpoint);
  return endpoint;
}

void Broker::unregisterInstance(const std::shared_ptr<Endpoint> &endpoint) {
  if (!endpoint) return;
  std::lock_guard<std::mutex> lock(impl_->mutex);
  impl_->invalidate(*endpoint);
  endpoint->present = false;
  impl_->send("REMOVED\t" + impl_->prefix(*endpoint));
  impl_->endpoints.erase(std::remove(impl_->endpoints.begin(), impl_->endpoints.end(), endpoint), impl_->endpoints.end());
}

void Broker::arm(const std::shared_ptr<Endpoint> &endpoint) {
  if (!endpoint) return;
  std::lock_guard<std::mutex> lock(impl_->mutex);
  if (!endpoint->present || std::find(impl_->endpoints.begin(), impl_->endpoints.end(), endpoint) == impl_->endpoints.end()) return;
  for (const auto &other : impl_->endpoints) if (other != endpoint && other->armed) impl_->invalidate(*other);
  impl_->invalidate(*endpoint);
  endpoint->armed = true;
  endpoint->lastContact = Clock::now();
}

void Broker::disarm(const std::shared_ptr<Endpoint> &endpoint) {
  if (!endpoint) return;
  std::lock_guard<std::mutex> lock(impl_->mutex);
  impl_->invalidate(*endpoint);
}

bool Broker::isArmed(const std::shared_ptr<Endpoint> &endpoint) const {
  if (!endpoint) return false;
  std::lock_guard<std::mutex> lock(impl_->mutex);
  return endpoint->present && endpoint->armed;
}

std::string Broker::identity(const std::shared_ptr<Endpoint> &endpoint) const {
  if (!endpoint) return "Unavailable";
  std::lock_guard<std::mutex> lock(impl_->mutex);
  return endpoint->label;
}

std::string Broker::instanceId(const std::shared_ptr<Endpoint> &endpoint) const {
  return endpoint ? endpoint->id : std::string();
}

bool Broker::isCurrent(const std::shared_ptr<Endpoint> &endpoint, std::uint64_t generation) const {
  if (!endpoint) return false;
  std::lock_guard<std::mutex> lock(impl_->mutex);
  return endpoint->present && endpoint->armed && endpoint->generation == generation;
}

void Broker::publish(const std::shared_ptr<Endpoint> &endpoint, std::vector<Parameter> parameters) {
  if (!endpoint) return;
  std::lock_guard<std::mutex> lock(impl_->mutex);
  if (!endpoint->present) return;
  endpoint->parameters = std::move(parameters);
  ++endpoint->revision;
  endpoint->snapshotDirty = true;
}

std::vector<Command> Broker::takePending(const std::shared_ptr<Endpoint> &endpoint) {
  std::vector<Command> result;
  if (!endpoint) return result;
  std::lock_guard<std::mutex> lock(impl_->mutex);
  if (!endpoint->present || !endpoint->armed) { endpoint->pending.clear(); return result; }
  const auto now = Clock::now();
  for (const auto &pending : endpoint->pending) {
    if (pending.command.generation == endpoint->generation && now - pending.received <= kMaximumQueueAge)
      result.push_back(pending.command);
  }
  endpoint->pending.clear();
  return result;
}

void Broker::acknowledgeApplied(const std::shared_ptr<Endpoint> &endpoint, std::size_t count) {
  if (!endpoint) return;
  std::lock_guard<std::mutex> lock(impl_->mutex);
  impl_->reply(*endpoint, false, "APPLY", "APPLIED", std::to_string(count));
}

void Broker::reportError(const std::shared_ptr<Endpoint> &endpoint, const std::string &code, const std::string &detail) {
  if (!endpoint) return;
  std::lock_guard<std::mutex> lock(impl_->mutex);
  impl_->reply(*endpoint, true, "APPLY", code, detail);
}

void Broker::shutdown() {
  std::lock_guard<std::mutex> lifecycleLock(impl_->lifecycleMutex);
  impl_->stop();
  std::lock_guard<std::mutex> lock(impl_->mutex);
  for (const auto &endpoint : impl_->endpoints) impl_->invalidate(*endpoint);
  impl_->endpoints.clear();
}
} // namespace spektrafilm::midi
