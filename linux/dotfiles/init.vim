" =============================================================================
" Peter Sharpe's Neovim Configuration
" =============================================================================

" -----------------------------------------------------------------------------
" Core Settings
" -----------------------------------------------------------------------------
set number                      " Show line numbers
set relativenumber              " Relative line numbers (great for vim motions)
set cursorline                  " Highlight current line
set signcolumn=yes              " Always show sign column (for git/lsp signs)
set scrolloff=8                 " Keep 8 lines visible above/below cursor
set sidescrolloff=8             " Keep 8 columns visible left/right of cursor

" -----------------------------------------------------------------------------
" Indentation (Python-friendly defaults)
" -----------------------------------------------------------------------------
set expandtab                   " Use spaces instead of tabs
set tabstop=4                   " Tab width
set shiftwidth=4                " Indent width
set softtabstop=4               " Soft tab width
set smartindent                 " Smart auto-indentation
set autoindent                  " Copy indent from current line

" -----------------------------------------------------------------------------
" Search
" -----------------------------------------------------------------------------
set ignorecase                  " Case-insensitive search...
set smartcase                   " ...unless uppercase is used
set incsearch                   " Show matches as you type
set hlsearch                    " Highlight all matches

" -----------------------------------------------------------------------------
" Display
" -----------------------------------------------------------------------------
syntax enable                   " Enable syntax highlighting
set termguicolors               " True color support
set showmatch                   " Highlight matching brackets
set nowrap                      " Don't wrap lines by default
set linebreak                   " When wrapping, break at word boundaries
set colorcolumn=88              " Show column guide at 88 (Black formatter default)
set list                        " Show invisible characters
set listchars=tab:→\ ,trail:·,extends:›,precedes:‹,nbsp:␣

" -----------------------------------------------------------------------------
" Behavior
" -----------------------------------------------------------------------------
set mouse=a                     " Enable mouse support
set clipboard=unnamedplus       " Use system clipboard
set hidden                      " Allow switching buffers without saving
set updatetime=250              " Faster completion/diagnostics (default 4000ms)
set timeoutlen=500              " Faster key sequence completion
set undofile                    " Persistent undo history
set noswapfile                  " Disable swap files
set nobackup                    " Disable backup files
set splitright                  " Open vertical splits to the right
set splitbelow                  " Open horizontal splits below
set confirm                     " Confirm before closing unsaved buffers

" -----------------------------------------------------------------------------
" Completion
" -----------------------------------------------------------------------------
set wildmenu                    " Enhanced command-line completion
set wildmode=longest:full,full  " Complete longest common string, then each match
set completeopt=menuone,noselect " Better completion experience

" -----------------------------------------------------------------------------
" Performance
" -----------------------------------------------------------------------------
set lazyredraw                  " Don't redraw during macros
set synmaxcol=300               " Don't syntax highlight very long lines

" -----------------------------------------------------------------------------
" File Types
" -----------------------------------------------------------------------------
filetype plugin indent on       " Enable filetype detection and plugins

" Python-specific settings
autocmd FileType python setlocal colorcolumn=88

" YAML/JSON use 2-space indent
autocmd FileType yaml,json,javascript,typescript setlocal tabstop=2 shiftwidth=2 softtabstop=2

" Markdown wrap at 80 characters
autocmd FileType markdown setlocal wrap textwidth=80 colorcolumn=80

" -----------------------------------------------------------------------------
" Key Mappings
" -----------------------------------------------------------------------------
" Set leader key to space
let mapleader = " "

" Clear search highlighting with Escape
nnoremap <Esc> :nohlsearch<CR>

" Better window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Resize windows with arrow keys
nnoremap <C-Up> :resize +2<CR>
nnoremap <C-Down> :resize -2<CR>
nnoremap <C-Left> :vertical resize -2<CR>
nnoremap <C-Right> :vertical resize +2<CR>

" Move lines up/down in visual mode
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" Keep cursor centered when scrolling
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
nnoremap n nzzzv
nnoremap N Nzzzv

" Quick save
nnoremap <leader>w :w<CR>

" Quick quit
nnoremap <leader>q :q<CR>

" Buffer navigation
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>

" Toggle line wrapping
nnoremap <leader>tw :set wrap!<CR>

" Toggle relative line numbers
nnoremap <leader>tn :set relativenumber!<CR>

" Yank to end of line (consistent with D and C)
nnoremap Y y$

" Don't lose selection when indenting
vnoremap < <gv
vnoremap > >gv

" Paste without losing register content
xnoremap <leader>p "_dP

" -----------------------------------------------------------------------------
" Status Line (simple, no plugins needed)
" -----------------------------------------------------------------------------
set laststatus=2                " Always show status line
set statusline=
set statusline+=%#PmenuSel#
set statusline+=\ %f            " File path
set statusline+=\ %m            " Modified flag
set statusline+=%=              " Right align
set statusline+=%#CursorColumn#
set statusline+=\ %y            " File type
set statusline+=\ %l:%c         " Line:Column
set statusline+=\ %p%%          " Percentage through file
set statusline+=\ 

" -----------------------------------------------------------------------------
" Colorscheme
" -----------------------------------------------------------------------------
" Use a built-in dark colorscheme (no plugins needed)
set background=dark
silent! colorscheme habamax     " Modern built-in scheme (Neovim 0.9+)

