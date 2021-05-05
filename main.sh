#!/bin/bash

# Extends the base .gitconfig file with the dotfiles .gitconfig
# Expects the dotfiles repo to be sibilngs with root dot files
cat << EOT >> ../.gitconfig

[include]
  path = ./dotfiles/.gitconfig
EOT

