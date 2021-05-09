set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" Git
Plugin 'tpope/vim-fugitive'

" Text manipulation
Plugin 'terryma/vim-multiple-cursors'

" Syntax highlighting and stuff
Plugin 'scrooloose/syntastic'
Plugin 'pangloss/vim-javascript'
Plugin 'mxw/vim-jsx'
Plugin 'jelera/vim-javascript-syntax'
Plugin 'vasconcelloslf/vim-interestingwords'

" Purrrty choices
Plugin 'flazz/vim-colorschemes'

" File Navigation
Plugin 'scrooloose/nerdtree'
Plugin 'ctrlpvim/ctrlp.vim'

" snipmate
Plugin 'MarcWeber/vim-addon-mw-utils'
Plugin 'tomtom/tlib_vim'
Plugin 'garbas/vim-snipmate'


call vundle#end()
filetype plugin indent on

