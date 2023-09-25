# Module variables
SYS_PROP_MANUFACTURER=`grep_prop ro.product.system.manufacturer`
MOD_PROP_MANUFACTURER=`grep_prop ro.product.system.manufacturer $MODPATH/system.prop`
MOD_PROP_MODEL=`grep_prop ro.product.model $MODPATH/system.prop`
MOD_PROP_PRODUCT=`grep_prop ro.build.product $MODPATH/system.prop | tr '[:lower:]' '[:upper:]'`
MOD_PROP_VERSION=`grep_prop ro.build.version.release $MODPATH/system.prop`
MOD_PROP_SECURITYPATCH=`grep_prop ro.build.version.security_patch $MODPATH/system.prop`
MOD_PROP_VERSIONCODE=`date -d $MOD_PROP_SECURITYPATCH '+%y%m%d'`
MOD_PROP_MONTH=`date -d $MOD_PROP_SECURITYPATCH '+%B'`
MOD_PROP_YEAR=`date -d $MOD_PROP_SECURITYPATCH '+%Y'`

# Print head message
ui_print "- Installing, $MOD_PROP_MODEL ($MOD_PROP_PRODUCT) Prop - $MOD_PROP_MONTH $MOD_PROP_YEAR"

# Checking if the system sdk matches the module sdk
MOD_API=`grep_prop ro.build.version.sdk $MODPATH/system.prop | grep -ohE '[0-9]{2}'`

# Make sure device manufacturer was not disturbed 
# in order to fix few apps such as camera on Xiaomi devices
if [ $SYS_PROP_MANUFACTURER == $MOD_PROP_MANUFACTURER ]; then
  ui_print "- MANUFACTURER=$SYS_PROP_MANUFACTURER, running unsafe mode"
else
  sed -i 's/^ro.product.system.manufacturer/# ro.product.system.manufacturer/' $MODPATH/system.prop
  ui_print "- MANUFACTURER=$SYS_PROP_MANUFACTURER, running safe mode"
fi

# Make sure device API matches the one on the prop in order to avoid bootloop
if [ $API -gt $MOD_API ]; then
  ui_print "- SDK=$API, running unsafe mode"
else
  sed -i 's/^ro.build.version.sdk/# ro.build.version.sdk/' $MODPATH/system.prop
  ui_print "- SDK=$API, running safe mode"
fi

# Remove comments from files and place them, add blank line to end if not already present
# Scripts
for i in $(find $MODPATH -type f -name "*.sh" -o -name "*.prop" -o -name "*.rule"); do
  [ -f $i ] && { sed -i -e "/^#/d" -e "/^ *$/d" $i; [ "$(tail -1 $i)" ] && echo "" >> $i; } || continue
done

# Print footer message
ui_print "-  Script by Tesla, Telegram: @T3SL4"