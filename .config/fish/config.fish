# log in
set -Ux TZ UTC
set GPG_TTY $(tty)
set fish_greeting
touch $HOME/.hushlogin
set -Ux fish_user_paths \
    /opt/local/bin /bin /sbin /usr/bin /usr/sbin /usr/local/bin \
    /$HOME/.docker/bin \
    /opt/homebrew/bin /opt/homebrew/sbin /opt/homebrew/opt/fzf/bin \
    $HOME/.pyenv/bin $HOME/.pyenv/shims $HOME/Library/Python/3.11/bin \
    $HOME/.mozbuild/git-cinnabar \
    $fish_user_paths

# python env
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# SETUVAR
set -Ux icloud "$HOME/Library/Mobile Documents/com~apple~CloudDocs"
set -Ux fishsticks $(which fish)
set -Ux em $(which emacs)
set -Ux MANPATH /opt/local/share/man
set -Ux MCD $__fish_config_dir
set -Ux __fish_user_config $MCD/config.fish
set -Ux MC $__fish_user_config
set -Ux SIGNINGKEY 6EBDB51471AF2339
set -Ux EMAIL sean@seanbethard.net
set -Ux GIT_COMMITTER_EMAIL $EMAIL
set -Ux GIT_AUTHOR_EMAIL $EMAIL
set -Ux GIT_COMMITTER_NAME seanbethard
set -Ux GIT_AUTHOR_NAME "Sean Bethard"
set -Ux OPEN_DIRECTORY /Local/Default
set -Ux lsregister '/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister'
set -Ux HOMEBREW_PREFIX /opt/homebrew
set -Ux HOMEBREW_REPOSITORY /opt/homebrew
set -Ux HOMEBREW_CELLAR /opt/homebrew/Cellar
set -Ux HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK FALSE
set -Ux HOMEBREW_NO_INSTALL_CLEANUP FALSE
set -Ux HOMEBREW_NO_INSTALL_UPGRADE FALSE

# abbreviations
abbr --add kee keepassxc-cli

# completions
set -Ux FISH_COMPLETIONS_INSTALL /opt/homebrew/share/fish/
set -Ux FISH_COMPLETIONS_USER $HOME/.config/fish/completions/
kubectl completion fish | source
eksctl completion fish >$FISH_COMPLETIONS_USER/eksctl.fish

# secrets
function get_secret --description 'Get AWS secret.' --argument id secret
    echo $(aws secretsmanager get-secret-value --secret-id $id) | jq -r '.SecretString' | jq -r ".$secret"
end

# bookmarks
function make_favicons --description 'Convert image to 256x256, 64x64, 48x48, 32x32 and 16x16 favicons.' --argument image
    set -f no_extension (echo (string split . $image --fields 1))
    convert $TMP/$image -define icon:auto-resize=256,64,48,32,16 $no_extension.ico
    mv $TMP/$image $IMG
    mv $TMP/$no_extension.ico $ICO
end

# source $HOME/.cargo/env
