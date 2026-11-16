"""Check effective bindings against the actual packaged COSMIC defaults."""

import importlib.util
import json
import sys
from pathlib import Path

script, defaults, recommended, custom = map(Path, sys.argv[1:5])
spec = importlib.util.spec_from_file_location("cosmic_shortcuts", script)
cosmic = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cosmic)
cosmic.load_xkb(sys.argv[5])


def parse(path):
    result = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("//") or line in {"{", "}"}:
            continue
        match = cosmic.DEFAULT.fullmatch(line)
        assert match is not None, line
        modifiers, key, action = match.groups()
        keys = [m.strip() for m in modifiers.split(",") if m.strip()]
        if key is not None:
            keys.append(json.loads(key))
        identity = cosmic.binding(keys)
        assert identity not in result, f"Duplicate binding: {line}"
        result[identity] = action
    return result


native = parse(defaults)
generated = parse(recommended)
effective = native | generated
assert effective[cosmic.binding(["Meta", "m"])] == "Minimize"
assert effective[cosmic.binding(["Meta", "Tab"])] == "NextWorkspace"
assert effective[cosmic.binding(["Alt", "Tab"])] == "System(WindowSwitcher)"
assert effective[cosmic.binding(["Meta", "Shift", "s"])] == "System(Screenshot)"
assert effective[cosmic.binding(["Meta", "Shift", "1"])] == "SendToWorkspace(1)"
# Managed actions lose their old defaults, including aliases and empty bindings.
assert effective[cosmic.binding(["Meta", "w"])] == "Disable"
assert effective[cosmic.binding(["Meta", "Ctrl", "Right"])] == "Disable"
assert effective[cosmic.binding(["Meta"])] == "Disable"
# Unmapped native controls survive, including tiling, audio, and the screen lock.
assert effective[cosmic.binding(["Meta", "y"])] == "ToggleTiling"
assert effective[cosmic.binding(["XF86AudioRaiseVolume"])] == "System(VolumeRaise)"
assert effective[cosmic.binding(["Meta", "Escape"])] == "System(LockScreen)"

custom_effective = native | parse(custom)
assert custom_effective[cosmic.binding(["Meta", "q"])] == "Disable"
assert custom_effective[cosmic.binding(["Alt", "F4"])] == "Disable"
assert custom_effective[cosmic.binding(["Meta", "m"])] == "Minimize"
assert custom_effective[cosmic.binding(["Meta", "y"])] == "ToggleTiling"
assert custom_effective[cosmic.binding(["Meta", "Tab"])] == "System(WindowSwitcher)"
assert cosmic.binding(["Meta", "Page_Up"]) == cosmic.binding(["SUPER", "Prior"])

# Native action whitespace must not preserve aliases or strip command spaces.
whitespace = cosmic.generate(defaults.read_text(), {
    "actions": {"close": " Close \n", "spawn": ' Spawn ( "echo hello world" ) '},
    "bindings": {"close": [], "spawn": [["Meta", "Return"]]},
})
assert '(modifiers: [Super], key: "q"): Disable' in whitespace
assert 'Spawn("echo hello world")' in whitespace

# Reject collisions and malformed input during the build, before activation.
for configuration in [
    {"actions": {"a": "Close", "b": "Minimize"}, "bindings": {"a": [["Meta", "q"]], "b": [["SUPER", "q"]]}},
    {"actions": {"a": "Close"}, "bindings": {"a": [["Meta", "q", "w"]]}},
    {"actions": {"a": "Close"}, "bindings": {"a": [["Meta", "NotAKeysym"]]}},
    {"actions": {"a": "Close", "b": "Minimize"}, "bindings": {"a": [["Meta", "Page_Up"]], "b": [["SUPER", "Prior"]]}},
]:
    try:
        cosmic.generate(defaults.read_text(), configuration)
    except ValueError:
        pass
    else:
        raise AssertionError("Invalid configuration was accepted")

try:
    cosmic.generate("changed defaults format", {"actions": {}, "bindings": {}})
except ValueError:
    pass
else:
    raise AssertionError("Unknown default format was accepted")

print("COSMIC shortcut checks passed")
