#!/system/bin/sh

PIF_DIR="/data/adb/pif.json"

# If has backup restore it
[ -f "${PIF_DIR}.bak" ] && mv "${PIF_DIR}.bak" "$PIF_DIR"

# If the pif.json is missing then we create one from maintained project
if [ ! -f "$PIF_DIR" ]; then
  ui_print " -+ Missing $PIF_DIR, Downloading stable one for you."
  wget -O -q --show-progress "$PIF_DIR" "https://raw.githubusercontent.com/x1337cn/AutoPIF-Next/main/pif.json"
fi
