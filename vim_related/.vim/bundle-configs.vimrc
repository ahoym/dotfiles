" vim-jsx highlighting for .js files too
let g:jsx_ext_required = 0
let g:javascript_enable_domhtmlcss = 1

" ctrlP ignores
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*/node_modules/*

" vim-multiple-cursor
let g:multi_cursor_exit_from_insert_mode = 0

" NERDTree config
map  <C-l> :tabn<CR>
map  <C-h> :tabp<CR>
map  <C-n> :tabnew<CR>


" Toggle-ables
nnoremap <F5> :NERDTreeToggle<CR>

" Syntastic
let g:syntastic_javascript_checkers = ['eslint']
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

let local_eslint = finddir('node_modules', '.;') . '/.bin/eslint'
if matchstr(local_eslint, "^\/\\w") == ''
	let local_eslint = getcwd() . "/" . local_eslint
endif
if executable(local_eslint)
	let g:syntastic_javascript_eslint_exec = local_eslint
endif

