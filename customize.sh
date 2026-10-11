#!/system/bin/sh
# shellcheck disable=SC3043
# exec 3>&1 2>&1
# set -x

PKG="com.google.android.gms"
APK_NAME="GmsCore.apk"
APK_DEST_PATH="$MODPATH/system/priv-app/GmsCore"
APK_SOURCE="$(pm path $PKG | sed -n 's/^package://p')"

[ -f "$APK_SOURCE" ] || abort "$PKG not installed"
[ "$(pm path $PKG | sed -n 's/^package://p' | wc -l)" -eq 1 ] || abort "Multiple packages found for $PKG"
mkdir -p "$APK_DEST_PATH"
cp "$APK_SOURCE" "$APK_DEST_PATH/$APK_NAME"
set_perm_recursive "$APK_DEST_PATH" 0 0 0755 0644
