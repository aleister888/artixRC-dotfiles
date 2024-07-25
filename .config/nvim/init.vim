" Auto-instalar vim-plug
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
	silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
	autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif


let mapleader = "," " Definir la tecla leader


" Cargar plugins
call plug#begin('~/.local/share/nvim/plugged')


Plug 'ryanoasis/vim-devicons' " Iconos
Plug 'LunarWatcher/auto-pairs' " Auto-cerrar: ( { [
Plug 'morhetz/gruvbox' " Tema
Plug 'akinsho/bufferline.nvim' " Tabs

" Búsqueda
Plug 'ctrlpvim/ctrlp.vim'
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'

Plug 'dstein64/nvim-scrollview' " Scrollbar
let g:scrollview_excluded_filetypes = ['nerdtree']

Plug 'rrethy/vim-hexokinase', { 'do': 'make hexokinase' } " Pre-visualización de colores
let g:Hexokinase_highlighters = [ 'backgroundfull' ]

Plug 'sheerun/vim-polyglot' " Plugin para mejorar el resaltado de sintaxis
Plug 'lervag/vimtex' " Sugerencias de entrada (laTeX)
Plug 'neoclide/coc.nvim', {'branch': 'release'} " Sugerencias de entrada
let g:coc_global_extensions = [ 'coc-sh', 'coc-vimtex', 'coc-texlab' ]
inoremap <silent><expr> <s-tab> pumvisible() ? coc#pum#confirm() : "\<C-g>u\<tab>"
let g:coc_preferences = {
	\ 'suggest.maxCompleteItemCount': 50,
	\ 'suggest.detailField': 'menu',
	\ 'suggest.fixIncomplete': 1,
	\ 'coc.preferences.formatOnType': v:false,
	\ 'coc.preferences.formatOnSaveFiletypes': []
	\ }

Plug 'preservim/nerdtree' " Árbol de directorios
let NERDTreeShowHidden=1
nnoremap <silent><leader>t :NERDTreeToggle<CR>
" Customizar NERDTree con el esquema de colores Gruvbox
let g:NERDTreeDirArrowExpandable="+"
let g:NERDTreeDirArrowCollapsible="~"

set laststatus=3 " Mostar solo una barra de estado a la vez
au BufWinEnter * if &filetype == 'nerdtree' | setlocal winhighlight=StatusLineNC | endif
au BufWinLeave * if &filetype == 'nerdtree' | setlocal winhighlight= | endif

Plug 'sirver/ultisnips' " Snippets
let g:UltiSnipsSnippetDirectories = ['~/.config/nvim/snips']
let g:UltiSnipsExpandTrigger = '<tab>'
let g:UltiSnipsJumpForwardTrigger = '<tab>'
let g:UltiSnipsJumpBackwardTrigger = '<M-tab>'

Plug 'vim-airline/vim-airline' " Barra de estado
Plug 'vim-airline/vim-airline-themes'
let g:airline_theme = 'monochrome'
let g:airline_powerline_fonts = 0
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols = {}
let g:airline_symbols.branch = '   '
let g:airline_symbols.readonly = '󰌾 '
let g:airline_symbols.linenr = '   '
let g:airline_symbols.maxlinenr = '   '
let g:airline_symbols.dirty = '  '
let g:airline_symbols.colnr = ' C:'
let g:airline#extensions#whitespace#symbol = '( )'
let g:airline#extensions#whitespace#space_symbol = '( )'
let g:airline#extensions#whitespace#tab_symbol = '(\t)'
let g:airline#extensions#whitespace#trail_symbol = '().'
let g:airline#extensions#whitespace#leading_space = 1
let g:airline#extensions#whitespace#leading_tab = 1
let g:airline#extensions#wordcount#format = '%d w'

call plug#end()


" Mostramos en la barra de estado si
" auto-pairs y coc.nvim estan activos
function! CocStatus()
	return g:coc ? 'COC' : ''
endfunction
function! AutoPairsStatus()
	return g:pair ? '  {}' : ''
endfunction
function! TabStatus()
	return g:tab ? '  \t' : ''
endfunction
let g:airline_section_x = airline#section#create(['%{CocStatus()}%{AutoPairsStatus()}%{TabStatus()}'])


" Ajustes generales
syntax enable
set noexpandtab
set title encoding=UTF-8
set mouse=a scrolloff=10
set list hidden autochdir
set ttimeoutlen=0 wildmode=longest,list,full
set number relativenumber cursorline " Opciones del cursor
set ic | set ignorecase | set incsearch " Ajustes de búsqueda
set clipboard+=unnamedplus " Ajustes de pantalla


" Tema de colores
set background=dark termguicolors
set fillchars+=vert:\  " Espacio como separadores
colorscheme gruvbox
let g:gruvbox_contrast_dark = "hard"
autocmd VimEnter * highlight Normal ctermbg=none guibg=none
autocmd VimEnter * highlight NonText ctermbg=none guibg=none
autocmd VimEnter * highlight LineNr ctermbg=none guibg=none
autocmd VimEnter * highlight Folded ctermbg=none guibg=none
if !has('gui_running')
	set t_Co=256
endif


" Atajos de teclado:


" Presionando ,, vamos al principio de la palabra
function! MoveCursorLeftIfNeeded()
	let col = col('.')
	if col > 1
		call feedkeys("\<C-Left>")
	endif
endfunction
nnoremap <silent><leader>, :call MoveCursorLeftIfNeeded()<CR>

" Si presionamos: ,"   ,"   ,'   ,(   ,\   ,[   ,{
nnoremap <silent><leader>" :s/\%#\([^[:space:]]\+\)/"\1"/g<CR>:noh<CR>
nnoremap <silent><leader>' :s/\%#\([^[:space:]]\+\)/'\1'/g<CR>:noh<CR>
nnoremap <silent><leader>( :s/\%#\([^[:space:]]\+\)/(\1)/g<CR>:noh<CR>
nnoremap <silent><leader>\ :s/\%#\([^[:space:]]\+\)/\\(\1\\)/g<CR>:noh<CR>
nnoremap <silent><leader>[ :s/\%#\([^[:space:]]\+\)/[\1]/g<CR>:noh<CR>
nnoremap <silent><leader>{ :s/\%#\([^[:space:]]\+\)/{\1}/g<CR>:noh<CR>
nnoremap <silent><leader>$ :s/\%#\([^[:space:]]\+\)/$\1$/g<CR>:noh<CR>

" Activar/Desactivar comprobación ortografía
inoremap <silent><F3> <C-O>:setlocal spell! spelllang=es_es<CR>
inoremap <silent><F4> <C-O>:setlocal spell! spelllang=en_us<CR>
nnoremap <silent><F3> :setlocal spell! spelllang=es_es<CR>
nnoremap <silent><F4> :setlocal spell! spelllang=en_us<CR>

" Compilar documentos (laTeX)
au Filetype tex map <M-g> :! arara % && notify-send "Document Compiled" <CR><CR>
au Filetype tex map <M-S-g> :! xelatex % <CR>
au Filetype tex map <M-h> :! setsid /usr/bin/zathura $(echo % \| sed 's/tex$/pdf/') <CR><CR>
" Compilar documentos (Groff)
" Groff -> PDF
au Filetype groff map <M-g> :!
	\ groff -ms % -T pdf > $(echo % \| sed 's/ms$/pdf/') <CR><CR>
" Groff -> PS -> PDF
au Filetype groff map <M-S-g> :!
	\ groff -ms % -T ps > $(echo % \| sed 's/ms$/ps/')
	\ | time ps2pdf $(echo % \| sed 's/ms$/ps/') <CR>
" Pic -> Groff -> PDF
au Filetype groff map <C-g> :!
	\ pic % \| groff -ms -T pdf > $(echo % \| sed 's/ms$/pdf/') <CR>
" Pic -> Groff -> PS -> PDF
au Filetype groff map <C-S-g> :!
	\ pic % \| groff -ms -T ps > $(echo % \| sed 's/ms$/ps/')
	\ | time ps2pdf $(echo % \| sed 's/ms$/ps/') <CR>
" Abrir PDF
au Filetype groff map <M-w> :!
	\ setsid /usr/bin/zathura $(echo % \| sed 's/ms$/pdf/') <CR><CR>

" Activar/Desactivar sugerencias de entrada
let g:coc=1
function! CocToggle()
	let g:coc = !g:coc
	execute (g:coc ? 'CocEnable' : 'CocDisable')
endfunction
inoremap <F1> <C-O>:call CocToggle()<CR>
nnoremap <F1> :call CocToggle()<CR>

" Activar/Desactivar llaves automáticas
let g:pair = 1
function! PairToggle()
	let g:pair = !g:pair
	AutoPairsToggle
endfunction
inoremap <F2> <C-O>:call PairToggle()<CR>
nnoremap <F2> :call PairToggle()<CR>

" Alternar como se visualizan las tabulaciones
let g:tab = 1
set tabstop=2
function! TabExp()
	if &tabstop == 2
		set tabstop=8
	else
		set tabstop=2
	endif
	let g:tab = !g:tab
endfunction
nnoremap <F5> :call TabExp()<CR>


" Automatizar tareas:


" Función para ejecutar comandos en la terminal
let g:terminal_cmd = '!$(which $TERMINAL) $TERMTITLE scratchpad $TERMEXEC sh -c'
au BufWritePost ~/.dotfiles/dwmblocks/blocks.def.h
	\ execute g:terminal_cmd . ' "cd ~/.dotfiles/dwmblocks/' .
	\ '; doas make clean install" && killall dwmblocks; dwmblocks &'
au BufWritePost ~/.dotfiles/dwm/config.def.h
	\ execute g:terminal_cmd . ' "cd ~/.dotfiles/dwm/; doas make clean install"'
au BufWritePost ~/.dotfiles/st/config.def.h
	\ execute g:terminal_cmd . ' "cd ~/.dotfiles/st/; doas make clean install"'
au BufWritePost ~/.dotfiles/dmenu/config.def.h
	\ execute g:terminal_cmd . ' "cd ~/.dotfiles/dmenu/; doas make clean install"'
au BufWritePost ~/.dotfiles/.config/dunst/dunstrc :!pkill dunst; dunst &


" Auto acentuar carácteres con groff:
au Filetype groff inoremap á  \['a] | au Filetype groff inoremap Á  \['A]
au Filetype groff inoremap â  \[^a] | au Filetype groff inoremap Â  \[^A]
au Filetype groff inoremap ä  \[:a] | au Filetype groff inoremap Ä  \[:A]
au Filetype groff inoremap é  \['e] | au Filetype groff inoremap É  \['E]
au Filetype groff inoremap ê  \[^e] | au Filetype groff inoremap Ê  \[^E]
au Filetype groff inoremap ë  \[:e] | au Filetype groff inoremap Ë  \[:E]
au Filetype groff inoremap í  \['i] | au Filetype groff inoremap Í  \['I]
au Filetype groff inoremap î  \[^i] | au Filetype groff inoremap Î  \[^I]
au Filetype groff inoremap ï  \[:i] | au Filetype groff inoremap Ï  \[:I]
au Filetype groff inoremap ó  \['o] | au Filetype groff inoremap Ó  \['O]
au Filetype groff inoremap ô  \[^o] | au Filetype groff inoremap Ô  \[^O]
au Filetype groff inoremap ö  \[:o] | au Filetype groff inoremap Ö  \[:O]
au Filetype groff inoremap ú  \['u] | au Filetype groff inoremap Ú  \['U]
au Filetype groff inoremap û  \[^u] | au Filetype groff inoremap Û  \[^U]
au Filetype groff inoremap ü  \[:u] | au Filetype groff inoremap Ü  \[:U]
au Filetype groff inoremap ñ  \[~n] | au Filetype groff inoremap Ñ  \[~N]
au Filetype groff inoremap ç  \[,c] | au Filetype groff inoremap Ç  \[,C]
au Filetype groff inoremap ·  \[pc] | au Filetype groff inoremap ×  \[mu]

so ~/.config/nvim/bufferline.lua
