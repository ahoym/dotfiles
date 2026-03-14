DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Sourcing files from $DOTFILES_DIR"
source "$DOTFILES_DIR/.exports"
source "$DOTFILES_DIR/.aliases"

MYVIMRC=~/.vimrc

