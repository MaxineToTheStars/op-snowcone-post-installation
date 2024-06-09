# op-snowcone-post-install || install.sh
# --------------------------------
# Post installation script.
#
# Authors: @MaxineToTheStars <https://github.com/MaxineToTheStars>
# ----------------------------------------------------------------

# Shebang
#!/usr/bin/env bash

# Configuration
declare -r -a CONFIG_APPS_EXTERNAL_INSTALL=(
    "https://github.com/xManager-App/xManager/releases/latest/download/xManager.apk"
)
declare -r -a CONFIG_APPS_INSTALL=(
    "app.lawnchair"
    "app.organicmaps"
    "com.akylas.documentscanner"
    "com.aurora.store"
    "com.bnyro.clock"
    "com.darkempire78.opencalculator"
    "com.fsck.k9"
    "com.gitlab.mudlej.MjPdfReader"
    "com.hjiangsu.thunder"
    "com.looker.droidify"
    "com.nononsenseapps.feeder"
    "com.termux"
    "com.topjohnwu.magisk"
    "com.x8bit.bitwarden"
    "de.dennisguse.opentracks"
    "dev.octoshrimpy.quik"
    "helium314.keyboard"
    "io.anuke.mindustry"
    "me.jmh.authenticatorpro"
    "me.zhanghai.android.files"
    "net.minetest.minetest"
    "net.sourceforge.opencamera"
    "org.cromite.cromite"
    "org.fossify.calendar"
    "org.fossify.contacts"
    "org.fossify.gallery"
    "org.fossify.phone"
    "org.fossify.voicerecorder"
    "org.jellyfin.mobile"
    "org.joinmastodon.android.moshinda"
    "org.mozilla.fennec_fdroid"
    "org.videolan.vlc"
    "org.wikipedia"
)
declare -r -a CONFIG_APPS_REMOVE=(
    "org.lineageos.audiofx"
    "org.lineageos.eleven"
    "org.lineageos.etar"
    "org.lineageos.jelly"
    "org.lineageos.recorder"
)

# Constants
declare -r CONST_ROOT_DIRECTORY=$PWD

# Main
function main() {
    # Start the ADBd Server
    _internal_enable_adb

    # Install third-party applications
    _internal_install_third_party_apps

    # Modify Android settings
    _internal_modify_android_settings
}

# Enables ADB and launches as root
function _internal_enable_adb() {
    # Validate we are in the root project directory
    cd $CONST_ROOT_DIRECTORY

    # Log
    echo "[LOG] Enabling ADB..."

    # Start the ADBd Server
    adb start-server > /dev/null 2>&1
    adb kill-server  > /dev/null 2>&1
    adb start-server > /dev/null 2>&1

    # Wait for authorization
    read -n 1 -p "[ACTION] Authorize USB Debugging then press Enter: "

    # Connect as root
    adb root > /dev/null 2>&1

    # Log
    echo "[1/3] ADB enabled and started as root!"
}

# Installs all third party apps
function _internal_install_third_party_apps() {
    # Validate we are in the root project directory
    cd $CONST_ROOT_DIRECTORY

    # Log
    echo "[LOG] Adding external F-Droid repositories..."

    # Add repositories
    ./ctl repo add bitwarden https://mobileapp.bitwarden.com/fdroid/repo > /dev/null 2>&1
    ./ctl repo add cromite https://www.cromite.org/fdroid/repo           > /dev/null 2>&1
    ./ctl repo add izzyondroid https://apt.izzysoft.de/fdroid/repo       > /dev/null 2>&1

    # Update
    ./ctl update > /dev/null 2>&1

    # Log
    echo "[LOG] Installing applications..."

    # Iterate through list
    for appID in "${CONFIG_APPS_INSTALL[@]}"; do
        # Install via app ID
        ./ctl install $appID

        # Log
        echo "[LOG] Installed: $appID"
    done

    # Log
    echo "[LOG] Installing external applications..."

    # Iterate through the list
    for appURL in "${CONFIG_APPS_EXTERNAL_INSTALL[@]}"; do
        # Download
        curl --output ./resources/out.apk --location $appURL

        # Install
        adb install ./resources/out.apk > /dev/null 2>&1

        # Log
        echo "[LOG] Installed: $appURL"
    done


    # Log
    echo "[2/3] Done installing applications!"
}

# Modifies internal Android settings
function _internal_modify_android_settings() {
    # Validate we are in the root project directory
    cd $CONST_ROOT_DIRECTORY

    # Log
    echo "[LOG] Opening gallery application..."

    # Start the new gallery app first so the user grants the needed media permissions
    adb -d shell monkey -p org.fossify.gallery 1 > /dev/null 2>&1

    # Wait for user confirmation
    read -n 1 -p "[ACTION] Grant ALL file access then press Enter: "

    # Kill the application
    adb shell am force-stop org.fossify.gallery > /dev/null 2>&1

    # Log
    echo "[LOG] Uploading wallpaper..."

    # Upload wallpaper to phone
    adb push "./resources/wallpaper.png" "/storage/emulated/0/Download/wallpaper.png" > /dev/null 2>&1

    # Change the wallpaper
    adb shell am start \
    -a android.intent.action.ATTACH_DATA \
    -c android.intent.category.DEFAULT \
    -d file:///storage/emulated/0/Download/wallpaper.png \
    -t "image/*" \
    -e mimeType "image/*" > /dev/null 2>&1

    # Wait for user confirmation
    read -n 1 -p "[ACTION] Apply the wallpaper then press Enter: "

    # Log
    echo "[LOG] Removing non-critical apps..."

    # Remove unended apps
    for app in "${CONFIG_APPS_REMOVE[@]}"; do
        # Remove
        adb uninstall --user 0 $app > /dev/null 2>&1
    done

    # Log
    echo "[3/3] Done with system modifications!"
}

# Execute
main
