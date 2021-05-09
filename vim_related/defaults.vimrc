" Leader key
let mapleader=","
set t_Co=256
set background=dark
syntax on

" color scheme
colorscheme ir_black

" Keep backspace as delete
set backspace=indent,eol,start

" Highlight searched regexes, spacebar to remove highlights
set incsearch
set hlsearch
nnoremap <silent> <Space> :nohlsearch<Bar>:echo<CR>

" Split window placement
set splitbelow
set splitright

" Turn off backup files
set noswapfile
set nobackup
set nowb

" Line numbers
set number numberwidth=2
set ruler

" Tabs, indents, auto delete trailing spaces
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab
set smarttab
autocmd BufWritePre *.js,*.html,*.css,*.less,*.scss  :%s/\s\+$//e

" Highlight lines over 80 chars
highlight OverLength ctermbg=red ctermfg=white guibg=#592929
match OverLength /\%81v.\+/

" highlight ColorColumn ctermbg=235 guibg=#2c2d27
let &colorcolumn=join(range(81,999),",")

" Cntrl + J for newline
:nnoremap <NL> i<CR><ESC>l

