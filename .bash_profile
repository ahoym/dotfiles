DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$DOTFILES_DIR/.exports"
source "$DOTFILES_DIR/.aliases"

export MYVIMRC=~/.vimrc

# Homebrew
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# mise
if command -v mise &>/dev/null; then
  eval "$(mise activate bash)"
fi

# Bash completion (from Homebrew)
if type brew &>/dev/null && [ -r "$(brew --prefix)/etc/profile.d/bash_completion.sh" ]; then
  source "$(brew --prefix)/etc/profile.d/bash_completion.sh"
fi

