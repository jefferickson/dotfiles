" first install https://github.com/amix/vimrc
" and symlink this to ~/.vim_runtime/my_configs.vim

" vim-plug
if empty(glob('~/.vim/autoload/plug.vim'))
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
      \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
Plug 'sheerun/vim-polyglot'
Plug 'ayu-theme/ayu-vim'
call plug#end()
" NOTE: Run :PlugInstall to install these

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

" color scheme
set termguicolors
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
syntax on
let ayucolor="mirage"
colorscheme ayu
