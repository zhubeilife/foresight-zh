#!/bin/zsh
# Creates ~/Applications/Foresight 中文.app (runs launch.sh, with Foresight's icon) and adds it to
# the Dock. --uninstall removes both.
APP="$HOME/Applications/Foresight 中文.app"
ICON=/Applications/Foresight.app/Contents/Resources/AppIcon.icns

# Adds (add) or removes (remove) the app's Dock tile, then restarts the Dock if anything changed.
dock() {
  /usr/bin/python3 - "$1" "$APP" <<'PY'
import plistlib, subprocess, sys
from urllib.parse import quote
action, app = sys.argv[1], sys.argv[2]
url = "file://" + quote(app.rstrip("/")) + "/"
dock = plistlib.loads(subprocess.run(["defaults", "export", "com.apple.dock", "-"],
                                     capture_output=True, check=True).stdout)
apps = dock.get("persistent-apps", [])
mine = lambda t: t.get("tile-data", {}).get("file-data", {}).get("_CFURLString") == url
kept = [t for t in apps if not mine(t)]
if action == "add":
    if len(kept) < len(apps): sys.exit(0)
    kept.append({"tile-type": "file-tile", "tile-data": {"file-data": {
        "_CFURLString": url, "_CFURLStringType": 15}}})
elif len(kept) == len(apps):
    sys.exit(0)
dock["persistent-apps"] = kept
subprocess.run(["defaults", "import", "com.apple.dock", "-"], input=plistlib.dumps(dock), check=True)
subprocess.run(["killall", "Dock"])
print("Dock:", "added" if action == "add" else "removed")
PY
}

if [[ "$1" == --uninstall ]]; then
  dock remove
  rm -rf "$APP"
  echo "launcher removed"
  exit 0
fi

mkdir -p "$HOME/Applications"
rm -rf "$APP"
osacompile -o "$APP" -e 'do shell script "$HOME/tools/foresight-zh/launch.sh"' || exit 1
if [[ -f "$ICON" ]]; then
  cp "$ICON" "$APP/Contents/Resources/applet.icns"
  rm -f "$APP/Contents/Resources/Assets.car"
  /usr/libexec/PlistBuddy -c "Delete :CFBundleIconName" "$APP/Contents/Info.plist" 2>/dev/null
  codesign --force --sign - "$APP" >/dev/null 2>&1
  touch "$APP"
fi
echo "launcher installed: $APP"
dock add
