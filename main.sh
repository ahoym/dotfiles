#!/bin/bash

BASIC_PROGRESS_SIGIL=">>>>>>>>>>"
BASIC_EMPTY_PROGRESS="          "

# [include-git]
GITCONFIG_PATH="$(pwd)/.gitconfig"
# Extends the base .gitconfig file with the dotfiles .gitconfig
if ! grep -q $GITCONFIG_PATH ~/.gitconfig; then
echo "Adding [include] path for $(pwd)/.gitconfig to ~/.gitconfig"
cat << EOT >> ~/.gitconfig

[include]
  path = $(pwd)/.gitconfig

EOT
else
  echo "ahoym/dotfiles already [include]d in ~/.gitconfig. Skipping [include-git]."
fi
echo -ne "$BASIC_PROGRESS_SIGIL$BASIC_EMPTY_PROGRESS$BASIC_EMPTY_PROGRESS$BASIC_EMPTY_PROGRESS$BASIC_EMPTY_PROGRESS[20%]\r"

# [include-vim]
VIM_COPY_SIGIL="File copied from ahoym/vim_related"
# Copies vim related files/dirs if not existing
if [ ! -f ~/.vimrc ] || ! grep -q "$VIM_COPY_SIGIL" ~/.vimrc; then
  echo "Copying vim related files/dirs to root"
  cp -R ./vim_related/ ~
else
  echo "ahoym/vim_related already exists in ~/.vimrc. Skipping [include-vim]."
fi
echo -ne "$BASIC_PROGRESS_SIGIL$BASIC_PROGRESS_SIGIL$BASIC_EMPTY_PROGRESS$BASIC_EMPTY_PROGRESS$BASIC_EMPTY_PROGRESS[40%]\r"

# [include-brew]
# Check for homebrew, install if it doesn't exist. Update if it does
which -s brew
if [[ $? != 0 ]] ; then
  echo "[include-brew] Homebrew not found, installing."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  echo "[include-brew] Homebrew exists, updating."
  brew update
fi
echo -ne "$BASIC_PROGRESS_SIGIL$BASIC_PROGRESS_SIGIL$BASIC_PROGRESS_SIGIL$BASIC_EMPTY_PROGRESS$BASIC_EMPTY_PROGRESS[60%]\r"

# [include-nvm]
# Check for nvm, install if it doesn't exist.
if [ ! -d ~/.nvm ] ; then
  echo "[include-nvm] nvm not found, installing"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
else
  echo "[include-nvm] nvm found, installing stable and setting as default"
  . ~/.nvm/nvm.sh
  nvm install stable
  nvm alias default stable
fi
echo -ne "$BASIC_PROGRESS_SIGIL$BASIC_PROGRESS_SIGIL$BASIC_PROGRESS_SIGIL$BASIC_PROGRESS_SIGIL$BASIC_EMPTY_PROGRESS[80%]\r"


echo -ne "$BASIC_PROGRESS_SIGIL$BASIC_PROGRESS_SIGIL$BASIC_PROGRESS_SIGIL$BASIC_PROGRESS_SIGIL$BASIC_PROGRESS_SIGIL[100%]\r"
