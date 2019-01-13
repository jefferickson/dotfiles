" first install https://github.com/amix/vimrc
" and symlink this to ~/.vim_runtime/my_configs.vim

" vim-plug
if empty(glob('~/.vim/autoload/plug.vim'))
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
      \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
Plug 'ayu-theme/ayu-vim'
Plug 'matze/vim-move'
Plug 'easymotion/vim-easymotion'
Plug 'jpalardy/vim-slime'
Plug 'Integralist/vim-mypy'
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
call plug#end()
" NOTE: Run :PlugInstall to install these

" use arrow keys for something else in normal mode
noremap <Up> <NOP>
noremap <Down> <NOP>
noremap <Left> :bprev<CR>
noremap <Right> :bnext<CR>

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

" vsplit
nmap <leader>vs :vsplit

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

" overlength lines
highlight OverLength ctermbg=235 guibg=#2c2d27
let &colorcolumn="79,".join(range(119,999),",")

" lightline config
let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ 'active': {
      \   'left': [ ['mode', 'paste'],
      \             ['fugitive', 'readonly', 'filename', 'modified'] ]
      \ },
      \ 'component': {
      \   'readonly': '%{&filetype=="help"?"":&readonly?"🔒":""}',
      \   'modified': '%{&filetype=="help"?"":&modified?"+":&modifiable?"":"-"}',
      \   'fugitive': '%{exists("*fugitive#head")?fugitive#head():""}'
      \ },
      \ 'component_visible_condition': {
      \   'readonly': '(&filetype!="help"&& &readonly)',
      \   'modified': '(&filetype!="help"&&(&modified||!&modifiable))',
      \   'fugitive': '(exists("*fugitive#head") && ""!=fugitive#head())'
      \ },
      \ 'separator': { 'left': ' ', 'right': ' ' },
      \ 'subseparator': { 'left': ' ', 'right': ' ' }
      \ }

" vim-move
let g:move_key_modifier = 'C'

" vim-mypy
nmap <leader>ll :call mypy#ExecuteMyPy()<cr>

" omni-completion
autocmd CursorMovedI * if pumvisible() == 0|pclose|endif
autocmd InsertLeave * if pumvisible() == 0|pclose|endif
autocmd BufWritePre * lclose
