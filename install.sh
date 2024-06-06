# op-snowcone-post-install || run.sh
# --------------------------------
# Post installation script.
#
# Authors: @MaxineToTheStars <https://github.com/MaxineToTheStars>
# ----------------------------------------------------------------

# Shebang
#!/usr/bin/env bash

# Configuration
declare -r -a CONFIG_APPS_DISABLE=(
    "com.android.calculator2"
    "com.android.camera2"
    "com.android.contacts"
    "com.android.deskclock"
    "com.android.dialer"
    "com.android.documentsui"
    "com.android.gallery3d"
    "com.android.messaging"
)
declare -r -a CONFIG_APPS_INSTALL=(
    "app.lawnchair"
    "app.organicmaps"
    "com.akylas.documentscanner"
    "com.aurora.store"
    "com.bnyro.clock"
    "com.darkempire78.opencalculator"
    "com.fsck.k9"
    "com.hjiangsu.thunder"
    "com.looker.droidify"
    "com.nononsenseapps.feeder"
    "com.x8bit.bitwarden"
    "helium314.keyboard"
    "io.anuke.mindustry"
    "me.jmh.authenticatorpro"
    "me.zhanghai.android.files"
    "net.minetest.minetest"
    "net.sourceforge.opencamera"
    "net.typeblog.shelter"
    "org.cromite.cromite"
    "org.fossify.calendar"
    "org.fossify.contacts"
    "org.fossify.gallery"
    "org.fossify.messages"
    "org.fossify.phone"
    "org.jellyfin.mobile"
    "org.joinmastodon.android.moshinda"
    "org.mozilla.fennec_fdroid"
    "org.videolan.vlc"
    "org.wikipedia"
    "website.leifs.delta.foss"
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
declare -r -a CONST_SYSTEM_SETTINGS=( "ACCELEROMETER_ROTATION 0" )

# Main
function main() {
    _internal_enable_adb
    _internal_install_third_party_apps
    _internal_modify_android_settings
    echo "Done!"
}

# Enabled ADB and launches as root
function _internal_enable_adb() {
    # Validate we are in the root project directory
    cd $CONST_ROOT_DIRECTORY

    # Start the ADBd Server
    adb start-server
    adb kill-server
    adb start-server

    # Wait for authorization
    read -n 1 -p "Press Enter Once Authorized: "

    # Connect as root
    adb root
}

# Modifies internal Android settings
function _internal_modify_android_settings() {
    # Validate we are in the root project directory
    cd $CONST_ROOT_DIRECTORY

    # Change wallpaper
    adb push "./resources/studio_ghibli_cat.png" "/storage/emulated/0/Download/"
    adb shell am start \
    -a android.intent.action.ATTACH_DATA \
    -c android.intent.category.DEFAULT \
    -d file:///storage/emulated/0/Download/studio_ghibli_cat.png \
    -t 'image/*' \
    -e mimeType 'image/*'

    # Iterate through system settings
    for setting in "${CONST_SYSTEM_SETTINGS[@]}"; do
        # Modify setting
        adb shell settings put system ${setting,,}
    done

    # Remove unended apps
    for app in "${CONFIG_APPS_REMOVE[@]}"; do
        # Remove
        adb uninstall --user 0 $app
    done

    # Disable some system apps
    for app in "${CONFIG_APPS_DISABLE[@]}"; do
        # Clear data
        adb shell pm clear $app

        # Disable
        adb shell pm disable $app
    done
}

# Installs all third party apps located in /resources
function _internal_install_third_party_apps() {
    # Validate we are in the root project directory
    cd $CONST_ROOT_DIRECTORY

    # Add repositories
    ./ctl repo add bitwarden https://mobileapp.bitwarden.com/fdroid/repo
    ./ctl repo add cromite https://www.cromite.org/fdroid/repo
    ./ctl repo add izzyondroid https://apt.izzysoft.de/fdroid/repo

    # Update
    ./ctl update

    # Iterate through list
    for appID in "${CONFIG_APPS_INSTALL[@]}"; do
        # Install via app ID
        ./ctl install $appID
    done
}

# Execute
main
