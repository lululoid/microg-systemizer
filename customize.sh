#!/system/bin/sh
# shellcheck disable=SC3043
# exec 3>&1 2>&1
# set -x

PRIV_DIR="$MODPATH/system/priv-app"
PKGS="
com.google.android.gms,$PRIV_DIR/GmsCore,GmsCore.apk
com.android.vending,$PRIV_DIR/FakeStore,FakeStore.apk
"

echo "$PKGS" | while IFS= read -r entry; do
	[ -z "$entry" ] && continue

	PKG="$(echo "$entry" | cut -d',' -f1)"
	APK_NAME="$(echo "$entry" | cut -d',' -f3)"
	APK_DEST_PATH="$(echo "$entry" | cut -d',' -f2)"
	APK_SOURCE="$(pm path "$PKG" | sed -n 's/^package://p')"

	[ -n "$APK_SOURCE" ] || abort "$PKG not installed"
	[ "$(echo "$APK_SOURCE" | wc -l)" -eq 1 ] || abort "Multiple packages found for $PKG"
	mkdir -p "$APK_DEST_PATH"
	cp "$APK_SOURCE" "$APK_DEST_PATH/$APK_NAME" && echo "$PKG installed"
done
