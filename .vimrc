" Pathogen
execute pathogen#infect()
execute pathogen#helptags()

" line numbers
set number
set relativenumber

" vim-slime
let g:slime_target = "tmux"
let g:slime_default_config = {"socket_name": split($TMUX, ",")[0], "target_pane": ":.2"}

" vim-airline
set laststatus=2
let g:airline#extensions#tabline#enabled = 1

" vim-nerdtree
" autocmd vimenter * NERDTree
map <C-n> :NERDTreeToggle<CR>
" close vim if only thing open is nerdtree
" autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" vim-flake8
let g:flake8_show_in_gutter=1
autocmd BufWritePost *.py call Flake8()

" jedi-vim
autocmd FileType python setlocal completeopt-=preview

" Other modules installed
" jedi-vim
" nerdtree
" vim-airline
" vim-fugitive
" vim-slime
" vim-surround
" vim-sensible
" vim-commentary
" vim-flake8
