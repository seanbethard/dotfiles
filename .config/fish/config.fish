# login
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

# set environments
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval $(/opt/homebrew/bin/brew shellenv)

# SETUVAR
set -Ux mcd $__fish_config_dir
set -Ux __fish_user_config $mcd/config.fish
set -Ux mc $__fish_user_config
set -Ux etc $HOME/etc
set -Ux ico $etc/ico
set -Ux img $etc/img
set -Ux key $etc/key
set -Ux org $etc/org
set -Ux pkg $etc/pkg
set -Ux scr $etc/scr
set -Ux tmp $etc/tmp
set -Ux cloned $etc/git/cloned
set -Ux forked $etc/git/forked
set -Ux private $etc/git/private
set -Ux published $etc/git/published
set -Ux dotfiles $published/dotfiles
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
    convert $HOME/opt/tmp/$image -define icon:auto-resize=256,64,48,32,16 $no_extension.ico
    mv $HOME/opt/tmp/$image $HOME/opt/img
    mv $HOME/opt/tmp/$no_extension.ico $HOME/opt/
end

# key pairs
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
    echo "  Hostname $keyhostname" | tee -a $ssh_config
    echo "  User $user" | tee -a $ssh_config
    echo "  AddKeysToAgent yes" | tee -a $ssh_config
    echo "  UseKeychain yes" | tee -a $ssh_config
    echo "  IdentityFile $keyfile" | tee -a $ssh_config
end
