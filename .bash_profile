DOTFILES_DIR="$(dirname "$0")"

echo "Sourcing files from $DOTFILES_DIR"
source "$DOTFILES_DIR/.exports"
source "$DOTFILES_DIR/.aliases"

MYVIMRC=~/.vimrc

