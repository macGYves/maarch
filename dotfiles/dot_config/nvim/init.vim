set number relativenumber

set expandtab
set tabstop=4
set shiftwidth=4

" Save current file as sudo user
cmap w!! :SudaWrite

"
" vim-plug section
" 
call plug#begin(stdpath('data') . '/plugged')

Plug 'https://github.com/lambdalisue/suda.vim.git'

call plug#end()
