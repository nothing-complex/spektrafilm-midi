// Included inside the plugin's private namespace after parameter helpers.
// All functions in this file are called exclusively from allowed OFX actions.
OfxStatus applyParameterSemantics(InstanceData *data, const char *changedName);

bool midiParamAvailable(OfxParamSetHandle paramSet, OfxParamHandle handle) {
  for (int depth = 0; handle && depth < 8; ++depth) {
    OfxPropertySetHandle props = nullptr;
    if (gParamHost->paramGetPropertySet(handle, &props) != kOfxStatOK || !props) return false;
    int secret = 0, enabled = 1;
    gPropHost->propGetInt(props, kOfxParamPropSecret, 0, &secret);
    gPropHost->propGetInt(props, kOfxParamPropEnabled, 0, &enabled);
    if (secret || !enabled) return false;
    char *parent = nullptr;
    if (gPropHost->propGetString(props, kOfxParamPropParent, 0, &parent) != kOfxStatOK || !parent || !parent[0]) return true;
    handle = paramHandleForName(paramSet, parent);
    if (!handle) return false;
  }
  return false;
}

bool midiParamUnanimated(OfxParamHandle handle) {
  if (!handle || !gParamHost->paramGetNumKeys) return false;
  unsigned int keys = 0;
  if (gParamHost->paramGetNumKeys(handle, &keys) != kOfxStatOK || keys != 0) return false;
  OfxPropertySetHandle props = nullptr;
  if (gParamHost->paramGetPropertySet(handle, &props) != kOfxStatOK || !props) return false;
  int animating = 0;
  // Expressions may animate a parameter without creating OFX keyframes.
  return gPropHost->propGetInt(props, kOfxParamPropIsAnimating, 0, &animating) != kOfxStatOK || animating == 0;
}

bool midiDependenciesUnanimated(OfxParamSetHandle paramSet, InstanceData *data, const std::string &id) {
  const auto check = [&](std::initializer_list<const char *> names) {
    for (const char *name : names) {
      if (!midiParamUnanimated(paramHandleForName(paramSet, name))) return false;
    }
    return true;
  };
  if (id == "hdrPreset")
    return check({"hdrTransfer", "hdrReferenceWhiteNits", "hdrPeakNits", "hdrToneMapping"});
  if (id == "hdrTransfer" || id == "hdrReferenceWhiteNits" || id == "hdrPeakNits" ||
      id == "hdrExposureEv" || id == "hdrToneMapping") return check({"hdrPreset"});
  if (id == "film" && dirUsesStockCalibration(data))
    return check({"dirGammaSameLayerRgb", "dirGammaRToGb", "dirGammaGToRb", "dirGammaBToRg", "dirUsesStockCalibration"});
  if (id == "dirGammaSameLayerRgb" || id == "dirGammaRToGb" || id == "dirGammaGToRb" || id == "dirGammaBToRg")
    return check({"dirUsesStockCalibration"});
  const bool printerValue = id == "printerLightR" || id == "printerLightG" || id == "printerLightB";
  if (id == "printerLightsGang" || id == "printerLightsGroup" ||
      (printerValue && (getBoolValue(data->printerLightsGang, false) || getBoolValue(data->printerLightsGroup, false))))
    return check({"printerLightR", "printerLightG", "printerLightB", "printerLightsGang", "printerLightsGroup"});
  return true;
}

std::vector<spektrafilm::midi::Parameter> midiReadParameters(OfxParamSetHandle paramSet, OfxTime time,
                                                        const char *onlyParameter = nullptr, bool mayQueryKeys = true) {
  std::vector<spektrafilm::midi::Parameter> parameters;
  for (const ParamDefault &entry : kParamDefaults) {
    if (onlyParameter && std::strcmp(entry.name, onlyParameter) != 0) continue;
    OfxParamHandle handle = paramHandleForName(paramSet, entry.name);
    OfxPropertySetHandle props = nullptr;
    if (!handle || gParamHost->paramGetPropertySet(handle, &props) != kOfxStatOK || !props) continue;
    char *rawType = nullptr;
    if (gPropHost->propGetString(props, kOfxParamPropType, 0, &rawType) != kOfxStatOK || !rawType) continue;
    const bool choice = std::strcmp(rawType, kOfxParamTypeChoice) == 0;
    const bool usesDouble = paramKindUsesDouble(entry.kind);
    StoredParamValue current{};
    if (!getParamValueAtTime(handle, time, entry, current)) continue;
    // OFX 1.4 limits key enumeration to InstanceChanged. The initial create
    // snapshot is deliberately unavailable until Arm MIDI runs in that action.
    const bool unanimated = mayQueryKeys && midiParamUnanimated(handle);
    const bool available = midiParamAvailable(paramSet, handle) && unanimated;
    char *label = nullptr;
    gPropHost->propGetString(props, kOfxPropLabel, 0, &label);
    int optionsCount = 0;
    std::string options;
    if (choice && gPropHost->propGetDimension(props, kOfxParamPropChoiceOption, &optionsCount) == kOfxStatOK) {
      for (int option = 0; option < optionsCount; ++option) {
        char *name = nullptr;
        if (gPropHost->propGetString(props, kOfxParamPropChoiceOption, option, &name) == kOfxStatOK && name) {
          if (option) options += '\n';
          options += name;
        }
      }
    }
    for (int component = 0; component < paramComponentCount(entry.kind); ++component) {
      spektrafilm::midi::Parameter param;
      param.id = entry.name;
      param.component = component;
      param.type = choice ? "choice" : entry.kind == ParamValueKind::Bool ? "bool" : usesDouble ? "double" : "int";
      param.defaultValue = usesDouble ? entry.doubleDefault[component] : entry.intDefault;
      param.value = usesDouble ? current.doubleValue[component] : current.intValue[component];
      param.label = label ? label : entry.name;
      param.choices = options;
      param.available = available;
      if (choice || entry.kind == ParamValueKind::Bool) {
        param.minimum = 0;
        param.maximum = choice ? std::max(optionsCount - 1, 0) : 1;
        param.step = 1;
      } else if (usesDouble) {
        param.minimum = -std::numeric_limits<double>::max();
        param.maximum = std::numeric_limits<double>::max();
        double bound = 0;
        if (gPropHost->propGetDouble(props, kOfxParamPropMin, component, &bound) == kOfxStatOK) param.minimum = bound;
        if (gPropHost->propGetDouble(props, kOfxParamPropMax, component, &bound) == kOfxStatOK) param.maximum = bound;
        const double span = param.maximum - param.minimum;
        param.step = std::isfinite(span) && span < 10000 ? std::clamp(span / 400.0, 0.0001, 1.0) :
          std::clamp(std::abs(param.defaultValue) * 0.01, 0.001, 1.0);
        if (param.id.find("Exposure") != std::string::npos || param.id.find("exposure") != std::string::npos ||
            param.id.find("PushPullStops") != std::string::npos) param.step = 0.05;
        if (param.id == "printerLightR" || param.id == "printerLightG" || param.id == "printerLightB") param.step = 0.1;
      } else {
        int minimum = std::numeric_limits<int>::min(), maximum = std::numeric_limits<int>::max();
        int bound = 0;
        if (gPropHost->propGetInt(props, kOfxParamPropMin, component, &bound) == kOfxStatOK) minimum = bound;
        if (gPropHost->propGetInt(props, kOfxParamPropMax, component, &bound) == kOfxStatOK) maximum = bound;
        param.minimum = minimum;
        param.maximum = maximum;
        param.step = 1;
      }
      if (!std::isfinite(param.minimum) || !std::isfinite(param.maximum) || param.minimum > param.maximum ||
          !std::isfinite(param.value)) param.available = false;
      parameters.push_back(std::move(param));
    }
  }
  return parameters;
}

void publishMidiSnapshot(OfxImageEffectHandle effect, InstanceData *data, OfxTime time, bool mayQueryKeys = true) {
  if (!data || !data->midiEndpoint || data->midiApplying) return;
  OfxParamSetHandle paramSet = nullptr;
  if (gEffectHost->getParamSet(effect, &paramSet) != kOfxStatOK || !paramSet) return;
  spektrafilm::midi::Broker::instance().publish(data->midiEndpoint, midiReadParameters(paramSet, time, nullptr, mayQueryKeys));
}

struct MidiSnapshotAfterAction {
  OfxImageEffectHandle effect;
  InstanceData *data;
  OfxTime time;
  ~MidiSnapshotAfterAction() {
    // Never allow allocations/transport failures to cross the C host boundary.
    try { publishMidiSnapshot(effect, data, time); } catch (...) {}
  }
};

void updateMidiStatus(InstanceData *data) {
  if (!data || !data->midiStatus) return;
  auto &broker = spektrafilm::midi::Broker::instance();
  if (!data->midiEndpoint) {
    gParamHost->paramSetValue(data->midiStatus, "Controller unavailable: loopback socket could not start.");
    return;
  }
  const std::string text = (broker.isArmed(data->midiEndpoint) ? "Armed - " : "Disarmed - ") +
    broker.identity(data->midiEndpoint) + ". Apply MIDI commits queued movement.";
  gParamHost->paramSetValue(data->midiStatus, text.c_str());
  if (data->midiTarget) {
    const std::string target = "MIDI target: " + broker.instanceId(data->midiEndpoint);
    gParamHost->paramSetValue(data->midiTarget, target.c_str());
  }
}

OfxStatus applyMidiCommands(OfxImageEffectHandle effect, InstanceData *data, OfxTime time) {
  auto &broker = spektrafilm::midi::Broker::instance();
  auto commands = broker.takePending(data->midiEndpoint);
  if (commands.empty()) {
    updateMidiStatus(data);
    broker.acknowledgeApplied(data->midiEndpoint, 0);
    return kOfxStatOK;
  }
  OfxParamSetHandle paramSet = nullptr;
  if (gEffectHost->getParamSet(effect, &paramSet) != kOfxStatOK || !paramSet) return kOfxStatFailed;
  if (gParamHost->paramEditBegin(paramSet, "Spektrafilm MIDI controls") != kOfxStatOK) {
    broker.reportError(data->midiEndpoint, "EDIT_BEGIN_FAILED", "The host refused the controller edit transaction.");
    return kOfxStatFailed;
  }
  struct EndEdit {
    OfxParamSetHandle paramSet;
    InstanceData *data;
    ~EndEdit() { data->midiApplying = false; gParamHost->paramEditEnd(paramSet); }
  } endEdit{paramSet, data};
  data->midiApplying = true;
  std::size_t applied = 0;
  for (const auto &command : commands) {
    if (!broker.isCurrent(data->midiEndpoint, command.generation)) break;
    const ParamDefault *entry = defaultForParam(command.parameter.c_str());
    if (!entry || command.component < 0 || command.component >= paramComponentCount(entry->kind)) continue;
    // Re-read after each semantic edit: stock/mode changes can alter availability
    // and linked parameters. Host values, never controller predictions, win.
    const auto schema = midiReadParameters(paramSet, time, entry->name);
    const auto parameter = std::find_if(schema.begin(), schema.end(), [&](const auto &param) {
      return param.id == command.parameter && param.component == command.component;
    });
    if (parameter == schema.end() || !parameter->available) {
      broker.reportError(data->midiEndpoint, "UNAVAILABLE_PARAMETER", command.parameter + " is hidden, disabled or animated.");
      continue;
    }
    if (!midiDependenciesUnanimated(paramSet, data, command.parameter)) {
      broker.reportError(data->midiEndpoint, "ANIMATED_DEPENDENCY", command.parameter + " would modify a linked animated parameter.");
      continue;
    }
    OfxParamHandle handle = paramHandleForName(paramSet, entry->name);
    StoredParamValue value{};
    if (!getParamValueAtTime(handle, time, *entry, value)) continue;
    double next = command.operation == spektrafilm::midi::Operation::Reset ? parameter->defaultValue :
      command.operation == spektrafilm::midi::Operation::Set ? command.value : parameter->value + command.value;
    if (!std::isfinite(next)) continue;
    next = std::clamp(next, parameter->minimum, parameter->maximum);
    if (paramKindUsesDouble(entry->kind)) value.doubleValue[command.component] = next;
    else value.intValue[command.component] = static_cast<int>(std::round(next));
    if (setParamValue(handle, value)) {
      applyParameterSemantics(data, entry->name);
      ++applied;
    } else broker.reportError(data->midiEndpoint, "SET_FAILED", command.parameter);
  }
  syncConditionalParamVisibility(data);
  updateMidiStatus(data);
  broker.acknowledgeApplied(data->midiEndpoint, applied);
  return kOfxStatOK;
}
