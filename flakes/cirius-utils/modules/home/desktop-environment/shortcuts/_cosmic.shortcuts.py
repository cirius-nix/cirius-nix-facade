"""Generate COSMIC's custom shortcut map, retaining unrelated native defaults."""

import ctypes
import json
import re
import sys
from pathlib import Path


MODIFIERS = {
    "meta": "Super",
    "super": "Super",
    "ctrl": "Ctrl",
    "control": "Ctrl",
    "alt": "Alt",
    "shift": "Shift",
}
ORDER = ["Super", "Ctrl", "Alt", "Shift"]
XKB = None
# The packaged cosmic-comp defaults use one binding per line. Reject changes to
# that format rather than silently failing to disable an old native binding.
DEFAULT = re.compile(
    r'\(modifiers:\s*\[([^]]*)\](?:,\s*key:\s*("[^"]*"))?\):\s*(.+),'
)


def load_xkb(path):
    global XKB
    XKB = ctypes.CDLL(path)
    XKB.xkb_keysym_from_name.argtypes = [ctypes.c_char_p, ctypes.c_int]
    XKB.xkb_keysym_from_name.restype = ctypes.c_uint32
    XKB.xkb_keysym_get_name.argtypes = [ctypes.c_uint32, ctypes.c_char_p, ctypes.c_size_t]
    XKB.xkb_keysym_get_name.restype = ctypes.c_int


def binding(keys):
    modifiers, symbols = set(), []
    for key in keys:
        if key.lower() in MODIFIERS:
            modifiers.add(MODIFIERS[key.lower()])
        else:
            symbols.append(key.lower() if len(key) == 1 else key)
    if len(symbols) > 1 or (not symbols and modifiers != {"Super"}):
        raise ValueError(f"COSMIC needs one keysym or Super alone: {keys!r}")
    symbol = symbols[0] if symbols else None
    if symbol is not None and not re.fullmatch(r"[A-Za-z0-9_]+", symbol):
        raise ValueError(f"Use an XKB keysym name for COSMIC: {symbol!r}")
    if symbol is not None:
        encoded = symbol.encode()
        code = XKB.xkb_keysym_from_name(encoded, 0) or XKB.xkb_keysym_from_name(encoded, 1)
        if not code:
            raise ValueError(f"Unknown XKB keysym for COSMIC: {symbol!r}")
        name = ctypes.create_string_buffer(128)
        if XKB.xkb_keysym_get_name(code, name, len(name)) <= 0:
            raise ValueError(f"Cannot name COSMIC keysym: {symbol!r}")
        symbol = name.value.decode()
    return tuple(m for m in ORDER if m in modifiers), symbol


def normalize_action(action):
    # Whitespace in native RON expressions is insignificant, but whitespace in
    # quoted Spawn commands must remain intact.
    return re.sub(
        r'"(?:\\.|[^"\\])*"|\s+',
        lambda match: match[0] if match[0].startswith('"') else "",
        action,
    )


def generate(defaults, configuration):
    actions = {name: normalize_action(action) for name, action in configuration["actions"].items()}
    bindings = configuration["bindings"]
    managed = {actions[name] for name in bindings if name in actions}
    result = {}
    for number, line in enumerate(defaults.splitlines(), 1):
        line = line.strip()
        if not line or line.startswith("//") or line in {"{", "}"}:
            continue
        match = DEFAULT.fullmatch(line)
        if match is None:
            raise ValueError(f"Unsupported cosmic-comp default at line {number}: {line}")
        modifiers, key, action = match.groups()
        if normalize_action(action) in managed:
            keys = [m.strip() for m in modifiers.split(",") if m.strip()]
            if key is not None:
                keys.append(json.loads(key))
            result[binding(keys)] = "Disable"

    assigned = {}
    for canonical, combinations in sorted(bindings.items()):
        if canonical not in actions:
            continue
        action = actions[canonical]
        for keys in combinations:
            key = binding(keys)
            if key in assigned and assigned[key] != action:
                raise ValueError(f"Conflicting COSMIC actions for {keys!r}")
            assigned[key] = action
    result.update(assigned)

    lines = ["{"]
    for (modifiers, key), action in sorted(result.items(), key=lambda item: str(item[0])):
        fields = f"modifiers: [{', '.join(modifiers)}]"
        if key is not None:
            fields += f", key: {json.dumps(key)}"
        lines.append(f"    ({fields}): {action},")
    return "\n".join(lines + ["}", ""])


if __name__ == "__main__":
    defaults, configuration, output = map(Path, sys.argv[1:4])
    load_xkb(sys.argv[4])
    output.write_text(generate(defaults.read_text(), json.loads(configuration.read_text())))
