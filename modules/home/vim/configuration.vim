  " Table of contents:
"   1. General
"   2. Interface
"   3. Appearence
"   4. Files
"   5. Indentation
"   6. Status line
"   7. Plugins
"     7a. NERDTree

" 1. General
set nocompatible
set history=5

filetype plugin on
filetype indent on

set autoread
au FocusGained,BufEnter * silent! checktime

" 2. Interface
set scrolloff=0
set sidescrolloff=0
set startofline
set foldcolumn=2

set wildmenu
set showmode
set noruler
set number

set mouse=
set backspace=indent,start

set smartcase
set hlsearch
set incsearch
set lazyredraw
set magic
set noshowmatch

set noerrorbells
set novisualbell

set noequalalways

" 3. Appearence
syntax enable

set encoding=utf8

set cursorcolumn
set cursorline
set number

" 4. Files
set nobackup
set nowriteany
set noswapfile

" 5. Indentation
set expandtab
set shiftwidth=2
set tabstop=2

set nolinebreak

set autoindent
set smartindent
set nowrap

" 6. Status line
set laststatus=2
set statusline=
set statusline+=\|\ %=
set statusline+=\ %F
set statusline+=\ %h
set statusline+=%r
set statusline+=%m
set statusline+=\ \|\ %l:%c
set statusline+=\ \|

" 7. Plugins
" 7a. NERDTree
nnoremap <C-t> :NERDTreeToggle<CR>

let g:NERDTreeDirArrowExpandable = "+"
let g:NERDTreeDirArrowCollapsible = "-"
let g:NERDTreeShowHidden = 1

" Start NERDTree when Vim is started without file arguments.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" Exit Vim if NERDTree is the only window remaining in the only tab.
autocmd BufEnter * if tabpagenr("$") == 1 && winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree() | call feedkeys(":quit\<CR>:\<BS>") | endif
