set nocompatible
filetype off

call plug#begin('~/.vim/plugged')

" Text manipulation
Plug 'mg979/vim-visual-multi'

" Syntax highlighting and stuff
Plug 'vasconcelloslf/vim-interestingwords'

" Purrrty choices
Plug 'flazz/vim-colorschemes'

" File Navigation
Plug 'scrooloose/nerdtree'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Snippets
Plug 'SirVer/ultisnips'

call plug#end()
filetype plugin indent on

