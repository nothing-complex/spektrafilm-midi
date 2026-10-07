#include "SpektraMidiControl.h"

#include <iostream>
#include <stdexcept>

using namespace spektrafilm::midi;

void require(bool result, const char *message) {
  if (!result) throw std::runtime_error(message);
}

int main() {
  try {
    const std::string text = "Film\tExp\n100% \xC3\xA6";
    std::string decoded;
    require(percentDecode(percentEncode(text), decoded) && decoded == text, "UTF-8/percent escaping round trip");
    require(!percentDecode("bad%", decoded) && !percentDecode("bad%G0", decoded), "malformed escaping rejected");
    require(!percentDecode("bad%00", decoded), "NUL rejected");
    Command command;
    std::string error;
    const auto parse = [&](const std::string &packet) {
      return parseCommand(packet, "session", "instance", 3, command, error);
    };
    require(parse("DELTA\t1\tsession\tinstance\t3\tfilmExposureEv\t0\t0.001"), "fractional delta preserved");
    require(command.value == 0.001 && command.operation == Operation::Delta, "delta has correct operation and precision");
    require(parse("RESET\t1\tsession\tinstance\t3\tdirGammaSameLayerRgb\t2") && command.component == 2,
            "vector component reset parsed");
    require(parse("SET\t1\tsession\tinstance\t3\tgrainEnabled\t0\t1"), "boolean set parsed");
    require(!parse("DELTA\t1\tsession\tinstance\t2\tfilmExposureEv\t0\t1") && error == "STALE_TARGET", "stale generation rejected");
    require(!parse("DELTA\t1\tother\tinstance\t3\tfilmExposureEv\t0\t1"), "wrong session rejected");
    require(!parse("DELTA\t1\tsession\tother\t3\tfilmExposureEv\t0\t1"), "wrong instance rejected");
    require(!parse("DELTA\t1\tsession\tinstance\t3\tfilmExposureEv\t3\t1"), "invalid component rejected");
    require(!parse("DELTA\t1\tsession\tinstance\t3\tfilmExposureEv\t0\tnan"), "NaN rejected");
    require(!parse("DELTA\t1\tsession\tinstance\t3\tfilmExposureEv\t0\t1e999"), "overflow rejected");
    require(!parse("DELTA\t1\tsession\tinstance\t3\tfilmExposureEv\t0\t1\textra"), "extra fields rejected");
    require(!parse("ARM\t1\tsession\tinstance\t3"), "remote arming rejected");
    require(!parse(std::string(9000, 'x')), "oversized packets rejected");

    auto &broker = Broker::instance();
    auto first = broker.registerInstance("First"), second = broker.registerInstance("Second");
    require(first && second, "loopback transport starts");
    require(broker.instanceId(first) != broker.instanceId(second), "instances have separate identities");
    require(!broker.isArmed(first) && !broker.isArmed(second), "instances begin disarmed");
    broker.arm(first);
    require(broker.isCurrent(first, 2), "arming advances generation");
    broker.arm(second);
    require(!broker.isArmed(first) && broker.isArmed(second), "arming is exclusive");
    require(!broker.isCurrent(first, 2), "switching target invalidates old generation");
    broker.disarm(second);
    require(!broker.isArmed(second), "explicit disarm succeeds");
    broker.unregisterInstance(first);
    broker.arm(first);
    require(!broker.isArmed(first), "removed endpoint cannot become an active target");
    broker.unregisterInstance(second);
    broker.shutdown();
    std::cout << "Wire parsing, targeting and transport lifecycle checks passed.\n";
    return 0;
  } catch (const std::exception &error) {
    std::cerr << error.what() << '\n';
    Broker::instance().shutdown();
    return 1;
  }
}
