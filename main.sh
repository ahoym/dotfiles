#!/bin/bash

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

# Copy vim related files/dirs to root
cp -R ./vim_related/ ~

