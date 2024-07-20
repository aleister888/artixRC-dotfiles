let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim' " Directorio donde instalar vim-plug
let plug_url = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim' " Url de vim-plug

" Instalar vim-plug si no lo está ya
if empty(glob(data_dir . '/autoload/plug.vim')) " Creamos los directorios necesarios
	silent execute '!wget -O ' . data_dir . '/autoload/plug.vim ' . plug_url
	autocmd VimEnter * PlugInstall --sync | source $MYVIMRC " Instalamos los plugins
endif

let mapleader = "," " Definir la tecla leader

" Cargar plugins
call plug#begin('~/.local/share/nvim/plugged')

" Iconos
Plug 'ryanoasis/vim-devicons'

" Auto-cerrar llaves, paréntesis, ...
Plug 'LunarWatcher/auto-pairs'

" Tema de colores
Plug 'morhetz/gruvbox'

" Pre-visualización de colores
Plug 'rrethy/vim-hexokinase', { 'do': 'make hexokinase' }
let g:Hexokinase_highlighters = [
\   'backgroundfull',
\ ]

" Sugerencias de entrada
Plug 'lervag/vimtex'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'neoclide/coc-vimtex'
inoremap <silent><expr> <s-tab> pumvisible() ? coc#pum#confirm() : "\<C-g>u\<tab>"

" Navegador de archivos
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.8' }
" Encontrar archivos con telescope
nnoremap <leader>f <cmd>Telescope find_files<cr>
nnoremap <leader>g <cmd>Telescope live_grep<cr>

" Árbol de directorios
Plug 'preservim/nerdtree'
let NERDTreeShowHidden=1
nnoremap <silent><leader>t :NERDTreeToggle<CR>
" Customizar NERDTree con el esquema de colores Gruvbox
autocmd vimenter * highlight NERDTreeDir guifg=#8ec07c
autocmd vimenter * highlight NERDTreeDirSlash guifg=#8ec07c
autocmd vimenter * highlight NERDTreeOpenable guifg=#83a598
autocmd vimenter * highlight NERDTreeClosable guifg=#83a598
autocmd vimenter * highlight NERDTreeExecFile guifg=#b8bb26
autocmd vimenter * highlight NERDTreeCWD guifg=#fabd2f

" Mostar solo una barra de estado a la vez
set laststatus=3
autocmd BufWinEnter * if &filetype == 'nerdtree' | setlocal winhighlight=StatusLineNC | endif
autocmd BufWinLeave * if &filetype == 'nerdtree' | setlocal winhighlight= | endif

" Snippets
Plug 'sirver/ultisnips'
let g:UltiSnipsSnippetDirectories = ['~/.config/nvim/snips']
let g:UltiSnipsExpandTrigger = '<tab>'
let g:UltiSnipsJumpForwardTrigger = '<tab>'
let g:UltiSnipsJumpBackwardTrigger = '<M-tab>'

" Barra de estado
Plug 'vim-airline/vim-airline'

" Ajustes de la barra de estado
let g:airline_theme = 'gruvbox'
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

let g:airline_section_x = airline#section#create(['%{CocStatus()}%{AutoPairsStatus()}'])

" Ajustes generales
syntax enable
set title encoding=UTF-8
set mouse=a scrolloff=10
set list hidden autochdir
set ttimeoutlen=0 wildmode=longest,list,full
set number relativenumber cursorline " Opciones del cursor
set ic | set ignorecase | set incsearch " Ajustes de búsqueda
set noshowmode | set clipboard+=unnamedplus " Ajustes de pantalla

" Tema de colores
set background=dark termguicolors
colorscheme gruvbox
hi Normal guibg=NONE ctermbg=NONE
if !has('gui_running')
	set t_Co=256
endif

" Atajos de teclado

" Presionando ,, vamos al principio de la palabra
" (solo tenemos en cuenta los espacios como separadores)
function! MoveCursorLeftIfNeeded()
	let col = col('.')
	if col > 1
		call feedkeys("\<C-Left>")
	endif
endfunction
nnoremap <silent><leader>, :call MoveCursorLeftIfNeeded()<CR>

" Si presionamos: ,"   ,"   ,'   ,(   ,\   ,[   ,{
" rodeamos la palabra por el limitador escogido
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
autocmd Filetype tex map <M-g> :! arara % && notify-send "Document Compiled" <CR><CR>
autocmd Filetype tex map <M-S-g> :! xelatex % <CR>
autocmd Filetype tex map <M-h> :! setsid /usr/bin/zathura $(echo % \| sed 's/tex$/pdf/') <CR><CR>

" Compilar documentos (Groff)

" Groff -> PDF
autocmd Filetype groff map <M-g> :!
	\ groff -ms % -T pdf > $(echo % \| sed 's/ms$/pdf/') <CR><CR>

" Groff -> PS -> PDF
autocmd Filetype groff map <M-S-g> :!
	\ groff -ms % -T ps > $(echo % \| sed 's/ms$/ps/')
	\ | time ps2pdf $(echo % \| sed 's/ms$/ps/') <CR>

" Pic -> Groff -> PDF
autocmd Filetype groff map <C-g> :!
	\ pic % \| groff -ms -T pdf > $(echo % \| sed 's/ms$/pdf/') <CR>

" Pic -> Groff -> PS -> PDF
autocmd Filetype groff map <C-S-g> :!
	\ pic % \| groff -ms -T ps > $(echo % \| sed 's/ms$/ps/')
	\ | time ps2pdf $(echo % \| sed 's/ms$/ps/') <CR>

" Abrir PDF
autocmd Filetype groff map <M-w> :!
	\ setsid /usr/bin/zathura $(echo % \| sed 's/ms$/pdf/') <CR><CR>

" C
" autocmd Filetype c map <M-g> :! gcc % -o $(echo % \| sed 's/.c$//') -lm <CR>
" autocmd Filetype c map <M-h> :terminal $PWD/$(echo % \| sed 's/.c$//')<CR>

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

" Automatizar tareas cuando se escribe en un archivo

" Función para ejecutar comandos en la terminal
let g:terminal_cmd = '!$(which $TERMINAL) $TERMTITLE scratchpad $TERMEXEC sh -c'

autocmd BufWritePost ~/.dotfiles/dwmblocks/blocks.def.h
	\ execute g:terminal_cmd . ' "cd ~/.dotfiles/dwmblocks/' .
	\ '; doas make clean install" && killall dwmblocks; dwmblocks &'
autocmd BufWritePost ~/.dotfiles/dwm/config.def.h
	\ execute g:terminal_cmd . ' "cd ~/.dotfiles/dwm/; doas make clean install"'
autocmd BufWritePost ~/.dotfiles/st/config.def.h
	\ execute g:terminal_cmd . ' "cd ~/.dotfiles/st/; doas make clean install"'
autocmd BufWritePost ~/.dotfiles/dmenu/config.def.h
	\ execute g:terminal_cmd . ' "cd ~/.dotfiles/dmenu/; doas make clean install"'

autocmd BufWritePost ~/.dotfiles/.config/dunst/dunstrc :!pkill dunst; dunst &

" Auto acentuar carácteres con groff

" a:
autocmd Filetype groff inoremap á  \['a] | autocmd Filetype groff inoremap Á  \['A]
autocmd Filetype groff inoremap â  \[^a] | autocmd Filetype groff inoremap Â  \[^A]
autocmd Filetype groff inoremap ä  \[:a] | autocmd Filetype groff inoremap Ä  \[:A]
" e:
autocmd Filetype groff inoremap é  \['e] | autocmd Filetype groff inoremap É  \['E]
autocmd Filetype groff inoremap ê  \[^e] | autocmd Filetype groff inoremap Ê  \[^E]
autocmd Filetype groff inoremap ë  \[:e] | autocmd Filetype groff inoremap Ë  \[:E]
" i:
autocmd Filetype groff inoremap í  \['i] | autocmd Filetype groff inoremap Í  \['I]
autocmd Filetype groff inoremap î  \[^i] | autocmd Filetype groff inoremap Î  \[^I]
autocmd Filetype groff inoremap ï  \[:i] | autocmd Filetype groff inoremap Ï  \[:I]
" o:
autocmd Filetype groff inoremap ó  \['o] | autocmd Filetype groff inoremap Ó  \['O]
autocmd Filetype groff inoremap ô  \[^o] | autocmd Filetype groff inoremap Ô  \[^O]
autocmd Filetype groff inoremap ö  \[:o] | autocmd Filetype groff inoremap Ö  \[:O]
" u:
autocmd Filetype groff inoremap ú  \['u] | autocmd Filetype groff inoremap Ú  \['U]
autocmd Filetype groff inoremap û  \[^u] | autocmd Filetype groff inoremap Û  \[^U]
autocmd Filetype groff inoremap ü  \[:u] | autocmd Filetype groff inoremap Ü  \[:U]
" misc.
autocmd Filetype groff inoremap ñ  \[~n] | autocmd Filetype groff inoremap Ñ  \[~N]
autocmd Filetype groff inoremap ç  \[,c] | autocmd Filetype groff inoremap Ç  \[,C]
autocmd Filetype groff inoremap ·  \[pc] | autocmd Filetype groff inoremap ×  \[mu]
