#!/usr/bin/env fish
source $my_config

# Remove .rustup, .cargo and .mozbuild directories.
# Do a user-wide install of mercurial repository.

rm -r $HOME/.cargo
rm -r $HOME/.mozbuild
rm -r $HOME/.rustup

set fish_user_paths "$(python3.11 -m site --user-base)/bin" $fish_user_paths
set $fish_user_paths $HOME/.cargo/bin $fish_user_paths
python3.11 -m pip install --user mercurial
curl https://hg.mozilla.org/mozilla-central/raw-file/default/python/mozboot/bin/bootstrap.py -O
python3 bootstrap.py
