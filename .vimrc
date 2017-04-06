" Pathogen
execute pathogen#infect()

" vim-slime
let g:slime_target = "tmux"

" vim-airline
set laststatus=2

" vim-nerdtree
" autocmd vimenter * NERDTree
map <C-n> :NERDTreeToggle<CR>
" close vim if only thing open is nerdtree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" Other modules installed
" delimitMate
" nerdtree
" vim-airline
" vim-fugitive
" vim-slime
" vim-surround
" vim-sensible
