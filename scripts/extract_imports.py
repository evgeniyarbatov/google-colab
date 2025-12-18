#!/usr/bin/env python3
import ast
import sys
import importlib.util

# Map import names to pip package names
PACKAGE_MAP = {
    "PIL": "Pillow",
    "cv2": "opencv-python",
    "sklearn": "scikit-learn",
}

# Modules to explicitly exclude from requirements
BLOCKLIST = {
    "gnss_lib_py",
    "tensorflow",
    "torchvision",
    "torch",
    "PIL",
    "s2geometry",
    "soundfile",
    "pydub",
    "opencv-python" "google",
}


def is_installed(module_name):
    """Check if a module is already installed."""
    try:
        spec = importlib.util.find_spec(module_name)
        return spec is not None
    except (ImportError, ModuleNotFoundError, ValueError):
        return False


mods = set()
source = sys.stdin.read()

# Split by lines and try to parse each potential code block
for line in source.split("\n"):
    if line.strip() and not line.strip().startswith("#"):
        try:
            for node in ast.walk(ast.parse(line)):
                if isinstance(node, ast.Import):
                    mods |= {n.name.split(".")[0] for n in node.names}
                elif isinstance(node, ast.ImportFrom) and node.module:
                    mods.add(node.module.split(".")[0])
        except SyntaxError:
            # Skip lines that aren't valid Python
            continue

# Filter out blocklisted modules
mods = {mod for mod in mods if mod not in BLOCKLIST}

# Filter out already installed modules
missing = {mod for mod in mods if not is_installed(mod)}

# Map to correct package names
packages = {PACKAGE_MAP.get(mod, mod) for mod in missing}

print("\n".join(sorted(packages)))
