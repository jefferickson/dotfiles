" while learning, disable arrow keys
noremap <Up> <NOP>
noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>

" line numbers
set number
set relativenumber

" always remove trailing whitespace
if has("autocmd")
    autocmd BufWritePre * :call CleanExtraSpaces()
endif

" Linting
let g:ale_lint_on_enter = 1

" better splitting
set splitright
set splitbelow

" vim-slime
let g:slime_target = "tmux"
let g:slime_default_config = {"socket_name": split($TMUX, ",")[0], "target_pane": ":.2"}
