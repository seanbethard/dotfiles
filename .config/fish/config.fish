# log in
set -Ux TZ UTC
set GPG_TTY $(tty)
set fish_greeting
touch $HOME/.hushlogin
set -Ux fish_user_paths \
    /opt/local/bin /bin /sbin /usr/bin /usr/sbin /usr/local/bin \
    /opt/homebrew/bin /opt/homebrew/sbin /opt/homebrew/opt/fzf/bin \
    $HOME/.pyenv/bin $HOME/.pyenv/shims $HOME/Library/Python/3.11/bin \
    $HOME/.mozbuild/git-cinnabar \
    $fish_user_paths

# set env
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval $(/opt/homebrew/bin/brew shellenv)

# SETUVAR
set -Ux MCD $__fish_config_dir
set -Ux __fish_user_config $MCD/config.fish
set -Ux MC $__fish_user_config
set -Ux SIGNINGKEY 55664FE1
set -Ux EMAIL sean@seanbethard.net
set -Ux GIT_COMMITTER_EMAIL $EMAIL
set -Ux GIT_AUTHOR_EMAIL $EMAIL
set -Ux GIT_COMMITTER_NAME $USER
set tmp $(echo $USER | grep -o .)
set -Ux GIT_AUTHOR_NAME "$(string upper $(echo $tmp[1]))$(echo $tmp[2])$(echo $tmp[3])$(echo $tmp[4]) $(string upper \
    $(echo $tmp[5]))$(echo $tmp[6])$(echo $tmp[7])$(echo $tmp[8])$(echo $tmp[9])$(echo $tmp[10])$(echo $tmp[11])"
set -Ux ETC $HOME/ETC
set -Ux ORG $ETC/ORG
set -Ux PKG $ETC/PKG
set -Ux IMG $ETC/IMG
set -Ux ICO $ETC/ICO
set -Ux SCREENSHOTS $ETC/SCREENSHOTS
set -Ux GIT $ETC/GIT
set -Ux CLONE $GIT/CLONE
set -Ux FORK $GIT/FORK
set -Ux DRAFT $GIT/DRAFT
set -Ux PUB $GIT/PUB
set -Ux DOT $PUB/dotfiles
set -Ux lsregister '/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister'

# abbreviations
abbr --add kee keepassxc-cli

# completions
kubectl completion fish | source
eksctl completion fish >$HOME/.config/fish/completions/eksctl.fish

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

# add FIDO ed25519 identity (ssh-add -K is deprecated)
function keygen --argument rounds keyhost email keyhostname user
    set -lx keyfile $HOME/.ssh/id_ed25519_$keyhost
    set -lx ssh_config $HOME/.ssh/config
    ssh-keygen -o -a $rounds -t ed25519 -f $keyfile -C $email
    eval "(ssh-agent -s)"
    chmod 700 $HOME/.ssh
    chmod 600 $keyfile
    chmod 644 $keyfile.pub
    ssh-add -K $keyfile
    echo '
         ' | tee -a $ssh_config
    echo "Host $keyhost" | tee -a $ssh_config
    echo " Hostname $keyhostname" | tee -a $ssh_config
    echo " User $user" | tee -a $ssh_config
    echo " AddKeysToAgent yes" | tee -a $ssh_config
    echo " UseKeychain yes" | tee -a $ssh_config
    echo " IdentityFile $keyfile" | tee -a $ssh_config
end
