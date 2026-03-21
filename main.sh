#!/bin/bash

BASIC_PROGRESS_SIGIL=">>>>>>>>>>"
BASIC_EMPTY_PROGRESS="          "

# [include-workspace]
# Create a WORKSPACE directory for git repos
if [ ! -d ~/WORKSPACE ] ; then
  echo "[include-workspace] WORKSPACE dir not found, creating."
  mkdir ~/WORKSPACE
else
  echo "[include-workspace] WORKSPACE dir found, skipping."
fi

# [include-git]
GITCONFIG_PATH="$(pwd)/.gitconfig"
# Extends the base .gitconfig file with the dotfiles .gitconfig
if ! grep -q $GITCONFIG_PATH ~/.gitconfig; then
echo "[include-git] Adding [include] path for $(pwd)/.gitconfig to ~/.gitconfig"
cat << EOT >> ~/.gitconfig

[include]
  path = $(pwd)/.gitconfig

EOT
else
  echo "[include-git] ahoym/dotfiles already [include]d in ~/.gitconfig. Skipping [include-git]."
fi
echo -ne "$BASIC_PROGRESS_SIGIL$BASIC_EMPTY_PROGRESS$BASIC_EMPTY_PROGRESS$BASIC_EMPTY_PROGRESS$BASIC_EMPTY_PROGRESS[20%]\r"

# [include-vim]
VIM_COPY_SIGIL="File copied from ahoym/vim_related"
# Copies vim related files/dirs if not existing
if [ ! -f ~/.vimrc ] || ! grep -q "$VIM_COPY_SIGIL" ~/.vimrc; then
  echo "[include-vim] Copying vim related files/dirs to root"
  if [ -f ~/.vimrc ]; then
    echo "[include-vim] Backing up existing ~/.vimrc to ~/.vimrc.bak"
    cp ~/.vimrc ~/.vimrc.bak
  fi
  if [ -d ~/.vim ]; then
    echo "[include-vim] Backing up existing ~/.vim to ~/.vim.bak"
    cp -R ~/.vim ~/.vim.bak
  fi
  cp -R ./vim_related/ ~
else
  echo "[include-vim] ahoym/vim_related already exists in ~/.vimrc. Skipping [include-vim]."
fi
echo -ne "$BASIC_PROGRESS_SIGIL$BASIC_PROGRESS_SIGIL$BASIC_EMPTY_PROGRESS$BASIC_EMPTY_PROGRESS$BASIC_EMPTY_PROGRESS[40%]\r"

# [include-xcode]
# Check for xcode command line tools, install if it doesn't exist.
if type xcode-select >&- && xpath=$( xcode-select --print-path ) &&
   test -d "${xpath}" && test -x "${xpath}" ; then
  echo "[include-xcode] xcode found, skipping."
else
  echo "[include-xcode] xcode not found, installing."
  xcode-select --install
fi
echo -ne "$BASIC_PROGRESS_SIGIL$BASIC_PROGRESS_SIGIL$BASIC_PROGRESS_SIGIL$BASIC_EMPTY_PROGRESS$BASIC_EMPTY_PROGRESS[60%]\r"

# [include-brew]
# Check for homebrew, install if it doesn't exist. Update if it does
which -s brew
if [[ $? != 0 ]] ; then
  echo "[include-brew] Homebrew not found, installing."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "[include-brew] Homebrew exists, updating."
  brew update
fi
echo -ne "$BASIC_PROGRESS_SIGIL$BASIC_PROGRESS_SIGIL$BASIC_PROGRESS_SIGIL$BASIC_PROGRESS_SIGIL$BASIC_EMPTY_PROGRESS[80%]\r"

# [include-mise]
# Check for mise, install if it doesn't exist.
if ! command -v mise &>/dev/null; then
  echo "[include-mise] mise not found, installing"
  curl https://mise.run | sh
  eval "$(~/.local/bin/mise activate bash)"
  mise use --global node@lts
else
  echo "[include-mise] mise found, upgrading"
  mise self-update
fi
echo -ne "$BASIC_PROGRESS_SIGIL$BASIC_PROGRESS_SIGIL$BASIC_PROGRESS_SIGIL$BASIC_PROGRESS_SIGIL$BASIC_PROGRESS_SIGIL[100%]\r"

