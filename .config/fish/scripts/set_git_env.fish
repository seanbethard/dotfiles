# large file storage filter
sudo git config --system filter.lfs.clean "git-lfs clean -- %f"
sudo git config --system filter.lfs.smudge "git-lfs smudge -- %f"
sudo git config --system filter.lfs.process "git-lfs filter-process"
sudo git config --system filter.lfs.required true

# core variables
mkdir $HOME/git
touch $HOME/git/ignore
set -Ux GITIGNORE $HOME/git/ignore
sudo git config --system core.editor emacs
sudo git config --system core.excludesfile $GITIGNORE
sudo git config --system core.ignoreCase true
sudo git config --system core.fileMode false
sudo git config --system core.hideDotFiles dotGitOnly
sudo git config --system core.logAllRefupdates true
sudo git config --system core.precomposeUnicode true
sudo git config --system core.repositoryformatversion 0

# merge options
sudo git config --system merge.conflictStyle zdiff3

# user variables
sudo git config --system gpg.minTrustLevel ultimate
sudo git config --system gpg.format openpgp
sudo git config --system gpg.openpgp.program $(which gpg)
sudo git config --system commit.gpgsign true
sudo git config --system user.signingkey $SIGNINGKEY
sudo git config --system user.email $GIT_COMMITTER_EMAIL
sudo git config --system user.name $GIT_COMMITTER_NAME
sudo git config --system author.email $GIT_AUTHOR_EMAIL
sudo git config --system author.name $GIT_AUTHOR_NAME
