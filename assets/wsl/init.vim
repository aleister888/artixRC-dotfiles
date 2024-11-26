" Auto-instalar vim-plug
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
	silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
	autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

let mapleader = "," " Definir la tecla leader

" Cargar y configurar plugins
if $USER !=# 'root'
	call plug#begin('~/.local/share/nvim/plugged')

	Plug 'alisdair/vim-armasm' " Sintaxis para ARM Assembly
	Plug 'LunarWatcher/auto-pairs' " Auto-cerrar: ( { [
	Plug 'morhetz/gruvbox' " Tema
	Plug 'neoclide/coc.nvim', {'branch': 'release'} " Sugerencias de entrada / autocompletado

	call plug#end()
endif

"################################
"# Configuración de los plugins #
"################################

" vim-armasm
let asmsyntax='armasm'
let filetype_inc='armasm'

let g:coc_preferences = {
	\ 'suggest.maxCompleteItemCount': 25,
	\ 'suggest.detailField': 'abbr',
	\ 'suggest.fixIncomplete': 0,
	\ 'coc.preferences.formatOnType': v:false,
	\ 'coc.preferences.formatOnSaveFiletypes': [],
	\ 'diagnostic.enable': v:false,
	\ 'signature.target': 'echo',
	\ 'suggest.preview': v:false
	\ }

"###########################
"# Configuración de neovim #
"###########################

syntax enable " Activar resaltado de sintaxis
set title " Cambiar el título de la ventana al del archivo
set encoding=UTF-8 " Establecer la codificación de caracteres en UTF-8
set mouse=a " Permitir el uso del mouse en todos los modos
set tags=/dev/null " Desactivar ctags
set hidden " Cambiar de buffer sin guardar los cambios
set autochdir " Cambiar el directorio de trabajo al del archivo abierto
set ttimeoutlen=0 " Tiempo de espera entre teclas
set wildmode=longest,list,full " Navegación y autocompletado de comandos
set pumheight=10 " Altura máxima del menú de autocompletado
set scrolloff=5 " Añadir márgenes en los extremos de la ventana
set wrap " Desactiva el ajuste de línea
set laststatus=3 " Mostar una sola barra de estado para todas las ventanas
set lazyredraw " No re-dibujar mientras se ejecutan macros
set number relativenumber cursorline " Opciones del cursor
set ignorecase incsearch " Ajustes de búsqueda
set list fillchars+=vert:\| " Líneas de separación vertical y carácteres invisibles
set list listchars=tab:\|\ ,trail:·,lead:·,precedes:<,extends:>

" Indentación y tabulación
autocmd FileType * setlocal noautoindent nosmartindent nocindent noexpandtab
autocmd FileType * setlocal copyindent preserveindent tabstop=8 shiftwidth=8

"###################
"# Tema de colores #
"###################

set t_Co=256

if $USER !=# 'root'
	colorscheme gruvbox
endif

set background=dark termguicolors

hi Normal ctermbg=none guibg=none
hi NonText ctermbg=none guibg=none
hi LineNr ctermbg=none guibg=none
hi Folded ctermbg=none guibg=none

hi Search guifg=#282828 guibg=#D5C4A1
hi IncSearch guifg=#282828 guibg=#D3869B
hi CurSearch guifg=#83A598 guibg=#282828

hi SpellBad guifg=#8EC07C guibg=#282828
hi SpellCap guifg=#8EC07C guibg=#282828
hi SpellLocal guifg=#FABD2F guibg=#282828
hi SpellRare guifg=#FE8019 guibg=#282828

hi ErrorMsg guifg=#FE8019 guibg=#282828

hi CocErrorSign guifg=#B16286
hi CocWarningSign guifg=#fabd2f
hi CocInfoSign guifg=#83a598
hi CocHintSign guifg=#8ec07c
hi CocFloating guibg=#282828
hi CocMenuSel guibg=#3C3836

hi CocErrorHighlight guifg=#B16286 guibg=#282828
hi CocUnusedHighlight guifg=#689D6A guibg=#282828
hi CocWarningHighlight guifg=#fabd2f guibg=#282828
hi CocInfoHighlight guifg=#83a598 guibg=#282828

"#####################
"# Atajos de teclado #
"#####################

" Plugins
inoremap <silent><expr> <s-tab> pumvisible() ? coc#pum#confirm() : "\<C-g>u\<tab>"

" Desplazarse por el texto
nnoremap <ScrollWheelUp> k<C-G>
nnoremap <ScrollWheelDown> j<C-G>
nnoremap <C-ScrollWheelUp> 5k<C-G>
nnoremap <C-ScrollWheelDown> 5j<C-G>
nnoremap <C-Up> 5k<C-G>
nnoremap <C-Down> 5j<C-G>
nnoremap = $<C-G>
nnoremap G :$<CR><C-G>
nnoremap gg :1<CR><C-G>

" Encapsular texto seleccionado
vnoremap " s"<C-r>""
vnoremap ' s'<C-r>"'
vnoremap ` s`<C-r>"`
vnoremap $ s$<C-r>"$
vnoremap _ s_<C-r>"_
vnoremap <leader>_ s__<C-r>"__
vnoremap ( s(<C-r>")
vnoremap ) s(<C-r>")
vnoremap { s{<C-r>"}
vnoremap } s{<C-r>"}
vnoremap [ s[<C-r>"]
vnoremap ] s[<C-r>"]

" Activar/Desactivar comprobación ortografía
nnoremap <silent><F4> :setlocal spell! spelllang=es_es<CR>
inoremap <silent><F4> <C-O>:setlocal spell! spelllang=es_es<CR>
nnoremap <silent><F5> :setlocal spell! spelllang=en_us<CR>
inoremap <silent><F5> <C-O>:setlocal spell! spelllang=en_us<CR>

" TeX
au Filetype tex vnoremap e s\emph{<C-r>"}
au Filetype tex vnoremap b s\textbf{<C-r>"}
au Filetype tex vnoremap i s\textit{<C-r>"}
au Filetype tex vnoremap h s\hl{<C-r>"}

" Shell
au FileType sh nmap <leader>f :CocList outline<CR>

" Activar/Desactivar sugerencias de entrada
	let g:coc=1
	function! CocToggle()
		let g:coc = !g:coc
		silent! execute (g:coc ? 'CocEnable' : 'CocDisable')
	endfunction
inoremap <silent><F1> <C-O>:call CocToggle()<CR>
nnoremap <silent><F1> :call CocToggle()<CR>

" Activar/Desactivar llaves automáticas
	let g:pair = 1
	function! PairToggle()
		let g:pair = !g:pair
		silent! AutoPairsToggle
	endfunction
inoremap <F2> <C-O>:call PairToggle()<CR>
nnoremap <F2> :call PairToggle()<CR>

"######################
"# Automatizar tareas #
"######################

" Borrar automaticamente los espacios sobrantes
autocmd BufWritePre * let currPos = getpos(".")
autocmd BufWritePre * %s/\s\+$//e
autocmd BufWritePre * %s/\n\+\%$//e
autocmd BufWritePre * cal cursor(currPos[1], currPos[2])
