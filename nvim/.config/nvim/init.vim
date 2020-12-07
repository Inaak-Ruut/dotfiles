"  Remap Caps Lock to Escape when you start up Vim:

"  au VimEnter * !xmodmap -e 'clear Lock' -e 'keycode 0x42 = Escape'

"  Restore Caps Lock to its regular function when you close Vim

au VimLeave * !xmodmap -e 'clear Lock' -e 'keycode 0x42 = Caps_Lock'


" plugin configuration with vim-plug

call plug#begin('~/.config/nvim/vim-plug/plugged')
Plug 'jpo/vim-railscasts-theme'
Plug 'junegunn/goyo.vim'
Plug 'dylanaraps/wal.vim'
Plug 'scrooloose/nerdtree'
Plug 'https://github.com/romainl/Apprentice'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'mboughaba/i3config.vim'
Plug 'vim-latex/vim-latex'
Plug 'morhetz/gruvbox'
Plug 'ying17zi/vim-live-latex-preview'
call plug#end()

set t_Co=256          "set colors to 256
set number
set relativenumber
set rnu
syntax on
set encoding=utf-8
set linebreak
set expandtab
set smarttab
set shiftwidth=4
set softtabstop=4
set tabstop=8
set autoindent
set ruler
set hidden
set ignorecase
set smartcase
set showmatch
set incsearch
set hls
set ls=2
set cursorline
set wrap
set linebreak
set backspace=indent,eol,start
set shell=/bin/bash
set completeopt =preview
" set textwidth=100
set wildmenu
set showmode
set cmdheight=1

" Airline configuration

"Airline Themes
let g:airline_theme='gruvbox'
"let g:airline_theme='dark'
"let g:airline_theme='badwolf'
"let g:airline_theme='ravenpower'
"let g:airline_theme='simple'
"let g:airline_theme='term'
"let g:airline_theme='ubaryd'
"let g:airline_theme='laederon'
"let g:airline_theme='kolor'
"let g:airline_theme='molokai'
"let g:airline_theme='powerlineish'

let g:Powerline_symbols = "fancy"
let g:Powerline_dividers_override = ["\Ue0b0","\Ue0b1","\Ue0b2","\Ue0b3"]
let g:Powerline_symbols_override = {'BRANCH': "\Ue0a0", 'LINE': "\Ue0a1", 'RO': "\Ue0a2"}
let g:airline_powerline_fonts = 1
let g:airline_right_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_left_alt_sep= ''
let g:airline_left_sep = ''

" air-line
let g:airline_powerline_fonts = 1

if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif

" unicode symbols
let g:airline_left_sep = '»'
let g:airline_left_sep = '▶'
let g:airline_right_sep = '«'
let g:airline_right_sep = '◀'
let g:airline_symbols.linenr = '␊'
let g:airline_symbols.linenr = '␤'
let g:airline_symbols.linenr = '¶'
let g:airline_symbols.branch = '⎇'
let g:airline_symbols.paste = 'ρ'
let g:airline_symbols.paste = 'Þ'
let g:airline_symbols.paste = '∥'
let g:airline_symbols.whitespace = 'Ξ'

" airline symbols
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols.branch = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = ''

" tab stuff

nnoremap tn :tabnew<cr>
nnoremap tk :tabnext<cr>
nnoremap tj :tabprev<cr>
nnoremap th :tabfirst<cr>
nnoremap tl :tablast<cr>

" backup/persistence settings

set undodir=~/.config/nvim/tmp/undo//
set backupdir=~/.config/nvim/tmp/backup//
set directory=~/.config/nvim/tmp/swap//
set backupskip=/tmp/*,/private/tmp/*"
set backup
set writebackup
set noswapfile

" persist (g)undo tree between sessions
set undofile
set history=100
set undolevels=100

" set <leader>
let mapleader=","

" remap Shift-Space to ESC
" :imap <S-Space> <Esc>

" enable mouse
set mouse=a

" syntax highlighting
syntax on
set termguicolors
colorscheme gruvbox

" Setting dark mode
set background=dark   

au ColorScheme * hi Normal ctermbg=none guibg=none
au ColorScheme * hi NonText ctermbg=none guibg=none


" Keybinds

" session management
let g:session_directory = "~/.nvim/session"
let g:session_autoload = "no"
let g:session_autosave = "no"
let g:session_command_aliases = 1

nnoremap <leader>so :OpenSession
nnoremap <leader>ss :SaveSession
nnoremap <leader>sd :DeleteSession<CR>
nnoremap <leader>sc :CloseSession<CR>


" visual reselect of just pasted
nnoremap gp `[v`]

"make space in normal mode add space
nnoremap <Space> i<Space><Esc>

" Press i to enter insert mode, and ii to exit.
inoremap ii <Esc>

" better scrolling
nnoremap <C-j> <C-d>
nnoremap <C-k> <C-u>
noremap j gj
noremap k gk

" consistent menu navigation
inoremap <C-j> <C-n>
inoremap <C-k> <C-p>

" open vimrc
nnoremap <leader>v :e  ~/.config/nvim/init.vim<CR>
nnoremap <leader>V :tabnew  ~/.config/nvim/init.vim<CR>

" reload all open buffers
nnoremap <leader>Ra :tabdo exec "windo e!"

"map next-previous jumps
nnoremap <leader>m <C-o>
nnoremap <leader>. <C-i>

" Keep search matches in the middle of the window.
nnoremap n nzzzv
nnoremap N Nzzzv

" Use sane regexes
nnoremap <leader>/ /\v
vnoremap <leader>/ /\v

" Use :Subvert search
nnoremap <leader>// :S /
vnoremap <leader>// :S /

" Use regular replace
nnoremap <leader>s :%s /
vnoremap <leader>s :%s /

" Use :Subvert replace
nnoremap <leader>S :%S /
vnoremap <leader>S :%S /

" clever-f prompt
let g:clever_f_show_prompt = 1
let g:clever_f_across_no_line = 1

" always open files in a new tab
autocmd VimEnter * tab all
autocmd BufAdd * exe 'tablast | tabe "' . expand( "<afile") .'"'

" Other:

" Make sure Vim returns to the same line when you reopen a file.

augroup line_return
    au!
    au BufReadPost *
        \ if line("'\"") > 0 && line("'\"") <= line("$") |
        \     execute 'normal! g`"zvzz' |
        \ endif
augroup END

" Macros:

" remove whitespace characters at beginning of line: :%s/^\s\+//e
nnoremap <leader>wsb :%s/^\s\s+//e
" remove whitespace characters at end of line: :%s/\s\+$//e
nnoremap <leader>wse :%s/\s\+$//e
" remove whitelist or empty lines: :g/^\s*$/d
nnoremap <leader>wsl :g/^\s*$/d
" reduce multipe empty lines to one
nnoremap <leader>wsll :%s/\n\{3,}/\r\r/e
" reduce multiple empty lines to one
nnoremap <leader>lt1:g/^$/,/./-j
" LaTeX (rubber) macro for compiling
nnoremap <leader>c :w<CR>:!rubber --pdf --warn all %<CR>
" View PDF macro; '%:r' is current file's root (base) name.
nnoremap <leader>v :!mupdf %:r.pdf &<CR><CR>
" F2 to open NerdTree
map <F2> :NERDTreeToggle<CR>

:nnoremap <silent> <F5> :let _s=@/ <Bar> :%s/\s\+$//e <Bar> :let @/=_s <Bar> :nohl <Bar> :unlet _s <CR>

nnoremap <leader>j i</p><CR><CR><p><Esc>
nnoremap <CR> i<CR><Esc>

" Quick pairs
  imap <leader>' ''<ESC>i
  imap <leader>" ""<ESC>i
  imap <leader>( ()<ESC>i
  imap <leader>[ {}<ESC>i
  
function! NumberToggle()
  if(&relativenumber == 1)
    set number
  else
    set relativenumber
  endif
endfunc

nnoremap <c-n> :call NumberToggle()<cr>

" Reload vimrc
  nnoremap <leader>rv :source<Space>$MYVIMRC<cr>

" Edit vimrc
  nnoremap <leader>ev :tabnew $MYVIMRC<cr>
