#pragma once

// The broker deliberately has no OpenFX dependency. Its worker only moves plain
// data. All host reads/writes belong to SpektraFilmPlugin's host action callbacks.
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

namespace spektrafilm::midi {

struct Parameter {
  std::string id;
  std::string type;
  int component = 0;
  double minimum = 0;
  double maximum = 1;
  double step = 0.01;
  double defaultValue = 0;
  double value = 0;
  bool available = true;
  std::string label;
  std::string choices;
};

enum class Operation { Delta, Set, Reset };

struct Command {
  Operation operation = Operation::Delta;
  std::string parameter;
  int component = 0;
  double value = 0;
  std::uint64_t generation = 0;
};

class Endpoint;

class Broker {
public:
  static Broker &instance();
  std::shared_ptr<Endpoint> registerInstance(const std::string &label);
  void unregisterInstance(const std::shared_ptr<Endpoint> &endpoint);
  void arm(const std::shared_ptr<Endpoint> &endpoint);
  void disarm(const std::shared_ptr<Endpoint> &endpoint);
  bool isArmed(const std::shared_ptr<Endpoint> &endpoint) const;
  std::string identity(const std::shared_ptr<Endpoint> &endpoint) const;
  std::string instanceId(const std::shared_ptr<Endpoint> &endpoint) const;
  bool isCurrent(const std::shared_ptr<Endpoint> &endpoint, std::uint64_t generation) const;
  // Called only by host callbacks, after their authoritative parameter reads.
  void publish(const std::shared_ptr<Endpoint> &endpoint, std::vector<Parameter> parameters);
  std::vector<Command> takePending(const std::shared_ptr<Endpoint> &endpoint);
  void acknowledgeApplied(const std::shared_ptr<Endpoint> &endpoint, std::size_t count);
  void reportError(const std::shared_ptr<Endpoint> &endpoint, const std::string &code, const std::string &detail);
  void shutdown();
  ~Broker();

  Broker(const Broker &) = delete;
  Broker &operator=(const Broker &) = delete;

private:
  Broker();
  struct Impl;
  std::unique_ptr<Impl> impl_;
};

// Shared wire helpers; strict parsing rejects malformed/oversized input rather
// than allowing arbitrary parameter names, nonfinite numbers or stale targets.
std::string percentEncode(const std::string &value);
bool percentDecode(const std::string &value, std::string &decoded);
bool parseCommand(const std::string &packet, const std::string &session,
                  const std::string &instance, std::uint64_t generation,
                  Command &command, std::string &error);

} // namespace spektrafilm::midi
