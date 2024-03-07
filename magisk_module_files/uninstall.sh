#!/system/bin/sh

PIF_DIRS="/data/adb/pif.json /data/adb/modules/playintegrityfix/pif.json"

# Loop true each PIF dirs
for PIF_DIR in $PIF_DIRS; do
  # If has backup restore it
  [ -f "${PIF_DIR}.old" ] && mv "${PIF_DIR}.old" "$PIF_DIR"

  # If the pif.json is missing then we create one from maintained project
  if [ ! -f "$PIF_DIR" ]; then
    ui_print " -+ Missing $PIF_DIR, Downloading stable one for you."
    wget -O -q --show-progress "$PIF_DIR" "https://raw.githubusercontent.com/x1337cn/AutoPIF-Next/main/pif.json"
  fi
done
