#!/usr/bin/env fish
source $my_config

# Firefox
set -gx FIREFOX_PKG $pkg/firefox

# ESR
set -lx ESR_PKG $FIREFOX_PKG/esr/firefox115.4esr.pkg
set -lx ESR_APP /Applications/Firefox.app
set -lx ESR_BIN_DIR $ESR_APP/Contents/MacOS
set $fish_user_paths $ESR_BIN_DIR $fish_user_paths
set -gx ESR_BIN $ESR_BIN_DIR/firefox

# Nightly
set -lx NIGHTLY_PKG $FIREFOX_PKG/nightly/firefox121.0a1.en.US.mac.dmg
set -lx NIGHTLY_APP "/Applications/Firefox Nightly.app"
set -lx NIGHTLY_BIN_DIR $NIGHTLY_APP/Contents/MacOS
set $fish_user_paths $NIGHTLY_BIN_DIR $fish_user_paths
set -gx NIGHTLY_BIN $NIGHTLY_BIN_DIR/firefox

# Darwin
set -lx MOZ_UNIFIED $FIREFOX_PKG/nightly_darwin/mozilla_unified
set -lx NIGHTLY_DARWIN $MOZ_UNIFIED/obj.aarch64.apple.darwin23.1.0
set -lx NIGHTLY_DARWIN_APP $NIGHTLY_DARWIN/dist/Nightly.app
set -lx NIGHTLY_DARWIN_BIN_DIR $NIGHTLY_DARWIN_APP/Contents/MacOS
set $fish_user_paths $NIGHTLY_DARWIN_BIN_DIR $fish_user_paths
set -gx NIGHTLY_DARWIN_BIN $NIGHTLY_DARWIN_BIN_DIR/firefox

# ESR, Nightly and Darwin Profiles
set -gx FIREFOX_PROFILES "$HOME/Library/Application Support/Firefox/Profiles"

# Mozilla extensions
set -lx MOZ_EXTENSION_DIR $FIREFOX_PKG/moz_extension
set -lx MOZ_KEEPASSXC keepassxc_browser-1.8.9.xpi
set -lx MOZ_NOSCRIPT noscript-11.4.28.xpi
set -lx MOZ_UBLOCK ublock_origin-1.53.0.xpi
set -lx MOZ_UMATRIX umatrix-1.4.4.xpi

# prepare Gecko extensions
rm -r $FIREFOX_PKG/gecko_extension
mkdir $FIREFOX_PKG/gecko_extension
set -lx GECKO_EXTENSION_DIR $FIREFOX_PKG/gecko_extension

function prepare_gecko_extensions --description 'Prepare Gecko extensions for a Firefox.'
    set -fx moz_extension {$MOZ_KEEPASSXC,$MOZ_NOSCRIPT,$MOZ_UBLOCK, $MOZ_UMATRIX}
    echo "Unpacking extensions into zippy"
    rm -r $MOZ_EXTENSION_DIR/zippy
    mkdir $MOZ_EXTENSION_DIR/zippy
    for zippy in $moz_extension
        set -lx moz_id $(echo $(string split - $zippy --right --fields 1))
        rm -r $MOZ_EXTENSION_DIR/zippy/$moz_id
        mkdir $MOZ_EXTENSION_DIR/zippy/$moz_id
        unzip -q $MOZ_EXTENSION_DIR/$zippy -d $MOZ_EXTENSION_DIR/zippy/$moz_id 2>/dev/null
        set -lx manifest $MOZ_EXTENSION_DIR/$moz_id/manifest.json
        if [ $moz_id = ublock_origin ]
            set -lx gecko_id $(jq -r ".browser_specific_settings | .gecko | .id" $manifest)
            rm -r $GECKO_EXTENSION_DIR/$gecko_id
            mkdir $GECKO_EXTENSION_DIR/$gecko_id
            echo "Moving contents of  $zippy into $GECKO_EXTENSION_DIR/$gecko_id"
            mv $MOZILLA_EXTENSIONS_DIR/zippy/$moz_id/* $GECKO_EXTENSION_DIR/$gecko_id
        else
            set -lx gecko_id $(jq -r ".applications | .gecko | .id" $manifest)
            rm -r $GECKO_EXTENSION_DIR/$gecko_id
            mkdir $GECKO_EXTENSION_DIR/$gecko_id
            mv $MOZILLA_EXTENSIONS_DIR/zippy/$moz_id/* $GECKO_EXTENSION_DIR/$gecko_id
        end
    end
    echo "Removing $MOZ_EXTENSION_DIR/zippy"
    rm -r $MOZ_EXTENSION_DIR/zippy
end

# set policy
function add_policy --description 'Set policy.' --argument firefox_app
    echo "Setting $firefox_app policy"
    set -fx moz_policy $MOZ_PREF/distribution/policies.json
    sudo mkdir -p $firefox_app/Resources/distribution
    sudo cp $moz_policy $firefox_app/Resources/distribution/policies.json
end

# launch services
function remove_launch_services_updater --description 'Remove updater.' --argument firefox_app
    echo "Removing $firefox_app LaunchServices updater"
    sudo rm $firefox_app/Contents/Library/LaunchServices/org.mozilla.updater
end

# profile chrome
function sync_profile_chrome \
    --description 'Update userChrome.js.' \
    --argument profile_dir profile_name profile_abbr
    set -fx chrome $MOZ_PREF/chrome/userChrome.css
    echo "Updating $profile_abbr userChrome.js"
    mkdir $profile_dir/chrome
    cp $chrome $profile_dir/chrome
end

# profile preferences
function sync_profile_preferences \
    --description 'Update user preferencs.' \
    --argument profile_dir profile_name profile_abbr
    echo "Updating $profile_abbr preferences."
    set -fx prefs $MOZ_PREF/pref/prefs.sanitized.js
    cp $SANITIZED_PREFS $profile_dir/prefs/prefs.js

end

# profile times
function sync_profile_times \
    --description 'Update user times.' \
    --argument profile_dir profile_name profile_abbr
    echo "Updating $profile_abbr times"
    set -times $MOZ_PREF/time/times.sanitized.json
    cp $SANITIZED_TIMES $profile_dir/times.json

end

# runners
function run_esr --description 'ESR runner.' --argument profile_name
    set -fx profile_dir $FIREFOX_PROFILES/$profile_name
    rm -r $profile_dir/*
    set -fx profile_abbr $(echo $(string split . $profile_name --right --fields 2))
    remove_launch_services_updater $ESR_APP
    prepare_gecko_extensions
    # load_gecko_extensions
    # sync_extensions_data
    # sync_gecko_bookmarks
    # repackage_omni
    sync_profile_chrome $profile_dir $profile_name $profile_abbr
    sync_profile_preferences $profile_dir $profile_name $profile_abbr
    sync_profile_times $profile_dir $profile_name $profile_abbr
    echo "Running Firefox ESR"
    $ESR_BIN -p $profile_abbr --no-remote --safe-mode --first-startup --headless
end

# TODO: nightly runner
# TODO: darwin runner

# TODO: load_gecko_extensions(): load contents of $GECKO_EXTENSION_DIR into profile
function load_gecko_profiles \
    --description 'Load Gecko extensions.' \
    --argument profile_name
    set -fx profile_abbr $(echo $(string split . $profile_name --right --fields 2))
    echo "Loading extensions into $profile_abbr"
end

# TODO: sync_extension_data(): add $EXTENSION_DATA to a profile
set -Ux EXTENSION_DATA $FIREFOX_PKG/extension_data
set -Ux KEEPASSXC_DATA $EXTENSION_DATA/keepassxc.json
set -Ux NOSCRIPT_DATA $EXTENSION_DATA/noscript.txt
set -Ux UBLOCK_DATA $EXTENSION_DATA/ublock.txt
set -Ux UMATRIX_DATA $EXTENSION_DATA/umatrix.txt
set -Ux GECKO_EXTENSION_DATA {$KEEPASSXC_DATA,$NOSCRIPT_DATA,$UBLOCK_DATA,$UMATRIX_DATA}

function sync_extensions_data \
    --description 'Import extensions data.' \
    --argument profile_name
    set -fx profile_abbr $(echo $(string split . $profile_name --right --fields 2))
    echo "Importing extensions data into $profile_abbr"
end

# TODO: sync_gecko_bookmarks(): import $GECKO_BOOKMARK to a profile
set -Ux GECKO_BOOKMARK $MOZ_PREF/bookmark/bookmarks.html

function sync_gecko_bookmarks \
    --description 'Import bookmarks.' \
    --argument profile_name
    set -fx profile_abbr $(echo $(string split . $profile_name --right --fields 2))
    echo "Importing bookmarks into $profile_abbr"
end

# TODO: repackage_omni(): repackage omni jar
: '
### Repackage JAR
mkdir omni
cp /opt/homebrew/Caskroom/firefox/118.0.2/Firefox.app/Contents/Resources/omni.ja omni
unzip -q omni/omni.ja
rm omni/omni.ja

grep -rl "firefox.settings.services.mozilla.com" omni
omni/modules/AppConstants.sys.mjs
omni/modules/backgroundtasks/BackgroundTask_message.sys.mjs
omni/modules/SearchUtils.sys.mjs

grep -rl "cdn.mozilla.net" omni
omni/chrome/toolkit/res/normandy/lib/NormandyApi.sys.mjs
omni/greprefs.js

cd omni
zip -0DXqr omni.ja *
rm /opt/homebrew/Caskroom/firefox/118.0.2/Firefox.app/Contents/Resources/omni.ja
cp omni.ja /opt/homebrew/Caskroom/firefox/118.0.2/Firefox.app/Contents/Resources
'
function repackage_omni \
    --description 'Repackage omni.ja.' \
    --argument firefox_app
    echo "Repackaging $firefox_app omni.ja"
end

# reinstall ESR
function reinstall_esr --description 'Reinstall Firefox.' --argument pkg
    echo "Reinstalling Firefox package $pkg"
    installer -pkg $ESR_PKG -target /
end
