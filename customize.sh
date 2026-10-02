#!/system/bin/sh
# shellcheck disable=SC3043

exec 3>&1 2>&1
set -x

PKG="com.google.android.gms"
APK_NAME="GmsCore.apk"
APK_DEST_PATH="$MODPATH/system/priv-app/GmsCore"

# The installer runs set_default_perm before sourcing this script, so anything
# written into $MODPATH here must be fixed up ourselves.
set_perms() {
	set_perm_recursive "$APK_DEST_PATH" 0 0 0755 0644
}

download_microg() {
	local apk
	apk="${TMPDIR}/$(basename "$1")"

	ui_print "Downloading $1"
	$BUSYBOX wget -q "$1" -O "$apk" 2>/dev/null || abort "Failed to download the MicroG APK"
	[ -s "$apk" ] || abort "Downloaded MicroG APK is empty"

	cp "$apk" "$APK_DEST_PATH/$APK_NAME"
}

# A /data copy of an older microG would outrank nothing yet still shadow the
# mounted APK, so bring it up to the same version instead of leaving it stale.
install_to_data() {
	ui_print "Installing $PKG into /data"
	pm install -r -d "$APK_DEST_PATH/$APK_NAME" ||
		abort "pm install failed. A signature mismatch needs: pm uninstall $PKG, then reinstall this module."
}

# Mount the newest microG available: reuse the installed one when it is already
# current, otherwise upgrade to the latest release.
install_microg() {
	local url latest have have_vc

	url=$($BUSYBOX wget -qO- "https://api.github.com/repos/microg/GmsCore/releases/latest" 2>/dev/null |
		$BUSYBOX grep -o '"browser_download_url": *"[^"]*com\.google\.android\.gms-[0-9]*\.apk"' |
		$BUSYBOX head -n1 |
		$BUSYBOX sed 's/.*: *"//;s/"$//')

	# The asset name carries the versionCode: com.google.android.gms-<vc>.apk
	latest="${url##*-}"
	latest="${latest%.apk}"
	[ -n "$latest" ] || abort "Could not find the MicroG APK in the latest release"

	# pm path prints "package:<path>" per APK; the first one is the base APK.
	have=$(pm path "$PKG" 2>/dev/null | $BUSYBOX sed -n 's/^package://p' | $BUSYBOX head -n1)
	have_vc=$(dumpsys package "$PKG" 2>/dev/null |
		$BUSYBOX grep -m1 'versionCode=' |
		$BUSYBOX sed 's/versionCode=\([0-9]*\).*/\1/')

	if [ -n "$have" ] && [ -f "$have" ] && [ -n "$have_vc" ] && [ "$have_vc" -ge "$latest" ]; then
		ui_print "Installed $PKG $have_vc is current; reusing it"
		cp "$have" "$APK_DEST_PATH/$APK_NAME"
		return 0
	fi

	ui_print "Upgrading $PKG to $latest"
	download_microg "$url"
}

main() {
	mkdir -p "$APK_DEST_PATH"
	install_microg
	install_to_data
	set_perms
}

main
