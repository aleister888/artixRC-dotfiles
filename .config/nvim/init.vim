" Auto-instalar vim-plug
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
	silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
	autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

let mapleader = "," " Definir la tecla leader

" Cargar y configurar plugins
if $USER !=# 'root'
	call plug#begin('~/.local/share/nvim/plugged')

	" Auto-indentar código (TeX, Java, Bash)
	Plug 'vim-autoformat/vim-autoformat'

	" Apariencia
	Plug 'ryanoasis/vim-devicons'      " Iconos
	Plug 'nvim-tree/nvim-web-devicons' " Iconos
	Plug 'morhetz/gruvbox'             " Tema
	" Visualización colores
	Plug 'rrethy/vim-hexokinase', { 'do': 'make hexokinase' }

	" Sintaxis
	Plug 'alisdair/vim-armasm'       " Lenguaje: ARM Assembly
	Plug 'uiiaoo/java-syntax.vim'    " Lenguaje: Java
	Plug 'cakebaker/scss-syntax.vim' " Lenguaje: SCSS
	Plug 'elkowar/yuck.vim'          " Lenguaje: yuck
	Plug 'andis-sprinkis/lf-vim'     " Configuración: lf

	" Menús
	Plug 'akinsho/bufferline.nvim' " Pestañas
	Plug 'mbbill/undotree'         " Mostrar árbol de cambios
	Plug 'nvim-tree/nvim-tree.lua' " Árbol de directorios

	" Lenguajes
	"   Markdown:
	Plug 'preservim/vim-markdown'
	Plug 'iamcco/markdown-preview.nvim', {
				\ 'do': { -> mkdp#util#install() },
				\ 'for': ['markdown', 'vim-plug'] }
	"   Latex:
	Plug 'lervag/vimtex'
	Plug 'sirver/ultisnips'

	" LSP
	Plug 'neoclide/coc.nvim', {'branch': 'release'}
	let g:coc_disable_startup_warning = 1
	let g:coc_global_extensions = [
				\ 'coc-sh',
				\ 'coc-vimtex',
				\ 'coc-texlab',
				\ 'coc-java',
				\ ]

	call plug#end()
endif

"################################
"# Configuración de los plugins #
"################################

" vim-autoformat
let g:formatdef_latexindent = '"latexindent -"'
let g:formatdef_astyle_java= '"astyle --style=allman --indent=spaces=4 -n"'
let g:formatters_java = ['astyle_java']
let g:autoformat_autoindent = 0
let g:autoformat_retab = 0
let g:autoformat_remove_trailing_spaces = 0
function! FAutoformat()
	let g:autoformat_autoindent = 1
	let g:autoformat_retab = 1
	let g:autoformat_remove_trailing_spaces = 1
	silent! execute "Autoformat"
	silent! execute "Autoformat"
	let g:autoformat_autoindent = 0
	let g:autoformat_retab = 0
	let g:autoformat_remove_trailing_spaces = 0
endfunction

" coc
inoremap <silent><expr> <s-tab>
			\ pumvisible() ? coc#pum#confirm() : "\<C-g>u\<tab>"
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
augroup my_coc_highlights
	au!
	au ColorScheme * highlight CocErrorSign guifg =   #B16286
	au ColorScheme * highlight CocWarningSign guifg = #fabd2f
	au ColorScheme * highlight CocInfoSign guifg =    #83a598
	au ColorScheme * highlight CocHintSign guifg =    #8ec07c
	au ColorScheme * highlight CocFloating guibg =    #282828
	au ColorScheme * highlight CocMenuSel guibg =     #3C3836
augroup END

" vim-armasm
let asmsyntax='armasm'
let filetype_inc='armasm'

" vim-hexokinase
let g:Hexokinase_highlighters = [ 'backgroundfull' ]

" vim-markdown
let g:vim_markdown_math = 1
let g:vim_markdown_syntax = 'on'
let g:vim_markdown_toc_autofit = 1
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_auto_insert_bullets = 0
let g:vim_markdown_new_list_item_indent = 0

" markdown-preview.nvim
let g:mkdp_auto_start = 0
let g:mkdp_refresh_slow = 1
let g:mkdp_page_title = '${name}'
let g:mkdp_browserfunc = 'OpenMarkdownPreview'
let g:mkdp_preview_options = { 'disable_filename': 1 }

function OpenMarkdownPreview (url)
	execute "silent ! setsid -f firefox --new-window " . a:url
endfunction

" vimtex
let g:vimtex_toc_config = { 'show_help': 0 }
let g:vimtex_mappings_enabled = 0
let g:vimtex_view_method = 'zathura'
let g:latex_view_general_viewer = 'zathura'
let g:vimtex_compiler_progname = 'nvr'
let g:vimtex_compiler_method = 'arara'
let g:vimtex_quickfix_mode = 0

" ultisnips
let g:UltiSnipsSnippetDirectories = ['~/.config/nvim/snips']
let g:UltiSnipsExpandTrigger = '<tab>'
let g:UltiSnipsJumpForwardTrigger = '<tab>'
let g:UltiSnipsJumpBackwardTrigger = '<M-tab>'

"###########################
"# Configuración de neovim #
"###########################

" Activar resaltado de sintaxis
syntax enable
" Título de la ventana: Título del archivo
set title
" Codificación de caracteres: UTF-8
set encoding=UTF-8
" Permitir el uso del mouse en todos los modos
set mouse=a
" Desactivar ctags
set tags=/dev/null
" Cambiar de buffer sin guardar los cambios
set hidden
" Cambiar el directorio de trabajo al del archivo
set autochdir
" Tiempo de espera entre teclas
set ttimeoutlen=0
" Navegación y autocompletado de comandos
set wildmode=longest,list,full
" Altura máxima del menú de autocompletado
set pumheight=10
" Añadir márgenes en los extremos de la ventana
set scrolloff=5
" Desactiva el ajuste de línea
set wrap
" Una sola barra de estado para todas las ventanas
set laststatus=3
" No re-dibujar mientras se ejecutan macros
set lazyredraw
" Opciones del cursor
set number relativenumber cursorline
" Ajustes de búsqueda
set ignorecase incsearch
" Líneas de separación vertical y carácteres invisibles
set list fillchars+=vert:\|
set list listchars=tab:\|\ ,trail:·,lead:·,precedes:<,extends:>
" Marcar la columna 80
set colorcolumn=80

" Indentación y tabulación
autocmd FileType * setlocal nosmartindent nocindent noexpandtab
autocmd FileType * setlocal copyindent preserveindent tabstop=8 shiftwidth=8

if $USER !=# 'root'
	set clipboard+=unnamedplus
	so ~/.config/nvim/config.lua
endif

"###################
"# Tema de colores #
"###################

set t_Co=256

if $USER !=# 'root'
	colorscheme gruvbox
endif

set background=dark termguicolors

hi Normal  ctermbg=none guibg=none
hi NonText ctermbg=none guibg=none
hi LineNr  ctermbg=none guibg=none
hi Folded  ctermbg=none guibg=none

autocmd VimEnter * hi Search     guifg=#282828 guibg=#D5C4A1
autocmd VimEnter * hi IncSearch  guifg=#282828 guibg=#D3869B
autocmd VimEnter * hi CurSearch  guifg=#83A598 guibg=#282828
autocmd VimEnter * hi SpellBad   guifg=#8EC07C guibg=#282828
autocmd VimEnter * hi SpellCap   guifg=#8EC07C guibg=#282828
autocmd VimEnter * hi SpellLocal guifg=#FABD2F guibg=#282828
autocmd VimEnter * hi SpellRare  guifg=#FE8019 guibg=#282828
autocmd VimEnter * hi ErrorMsg   guifg=#FE8019 guibg=#282828

"#####################
"# Atajos de teclado #
"#####################

" Plugins
nnoremap <silent><leader>t :NvimTreeToggle<CR>
nnoremap <silent><leader>u :UndotreeToggle<CR>
nnoremap <silent><leader>a :call FAutoformat()<CR>

" Abrir el mismo buffer en vertical/horizontal
nnoremap <leader>v :vsplit %<CR>
nnoremap <leader>V :split %<CR>

" Cambiar de pestaña
nnoremap <silent><leader>1 <Cmd>BufferLineGoToBuffer 1<CR>
nnoremap <silent><leader>2 <Cmd>BufferLineGoToBuffer 2<CR>
nnoremap <silent><leader>3 <Cmd>BufferLineGoToBuffer 3<CR>
nnoremap <silent><leader>4 <Cmd>BufferLineGoToBuffer 4<CR>
nnoremap <silent><leader>5 <Cmd>BufferLineGoToBuffer 5<CR>
nnoremap <silent><leader>6 <Cmd>BufferLineGoToBuffer 6<CR>
nnoremap <silent><leader>7 <Cmd>BufferLineGoToBuffer 7<CR>
nnoremap <silent><leader>8 <Cmd>BufferLineGoToBuffer 8<CR>
nnoremap <silent><leader>9 <Cmd>BufferLineGoToBuffer 9<CR>

" Desplazarse por el texto
nnoremap <ScrollWheelUp> k<C-G>
nnoremap <ScrollWheelDown> j<C-G>
nnoremap <C-ScrollWheelUp> 5k<C-G>
nnoremap <C-ScrollWheelDown> 5j<C-G>
nnoremap <C-Up> 5k<C-G>
nnoremap <C-Down> 5j<C-G>
nnoremap = $<C-G>
vnoremap = $h
nnoremap G :$<CR><C-G>
nnoremap gg :1<CR><C-G>

" Encapsular texto seleccionado
vnoremap " s"<C-r>""
vnoremap ' s'<C-r>"'
vnoremap ` s`<C-r>"`
vnoremap 2` s``<C-r>"``
vnoremap $ s$<C-r>"$
vnoremap _ s_<C-r>"_
vnoremap <leader>_ s__<C-r>"__
vnoremap ( s(<C-r>")
vnoremap ) s(<C-r>")
vnoremap { s{<C-r>"}
vnoremap } s{<C-r>"}
vnoremap [ s[<C-r>"]
vnoremap ] s[<C-r>"]
vnoremap ¿ s¿<C-r>"?
vnoremap ? s¿<C-r>"?

" Modo insert al final de la línea
nnoremap <C-i> A

" Abrir scratchpad en el directorio del archivo actual
nmap <silent><leader>s :execute '!' .
			\ 'setsid -f sh -c "' .
			\ expand(' $TERMINAL $TERMTITLE scratchpad ') .
			\ '"' <CR><CR>

" Activar/Desactivar comprobación ortografía
nnoremap <silent><F4> :setlocal spell! spelllang=es_es<CR>
inoremap <silent><F4> <C-O>:setlocal spell! spelllang=es_es<CR>
nnoremap <silent><F5> :setlocal spell! spelllang=en_us<CR>
inoremap <silent><F5> <C-O>:setlocal spell! spelllang=en_us<CR>


" TeX
au Filetype tex nmap <silent><leader>f <plug>(vimtex-toc-toggle)<CR>
au Filetype tex nmap <leader>g :VimtexCompile<CR>
au FileType tex nmap <leader>G :execute '!' .
			\ 'setsid -f ' .
			\ expand(' $TERMINAL $TERMTITLE scratchpad ') .
			\ expand(' $TERMEXEC xelatex ') . '%' <CR><CR>
au Filetype tex nmap <silent><leader>h :VimtexView<CR>
function! ToggleVimtexErrors()
	if len(filter(getwininfo(), 'v:val.quickfix')) > 0
		cclose
	else
		VimtexErrors
	endif
endfunction
au Filetype tex nmap <silent><leader>j :call ToggleVimtexErrors()<CR>
au Filetype tex nmap <silent><leader>k <plug>(vimtex-clean)<CR>
au Filetype tex vnoremap e s\emph{<C-r>"}
au Filetype tex vnoremap b s\textbf{<C-r>"}
au Filetype tex vnoremap i s\textit{<C-r>"}
au Filetype tex vnoremap t s\text{<C-r>"}
au Filetype tex vnoremap m s\texttt{<C-r>"}
au Filetype tex vnoremap h s\hl{<C-r>"}


" Markdown
au Filetype markdown nmap <silent><leader>h :MarkdownPreview<CR>
function! TocToggle()
	if get(getloclist(0, {'winid':0}), 'winid', 0)
		lclose
	else
		Tocv
	endif
endfunction
au FileType markdown nmap <silent><leader>f :call TocToggle()<CR>

" Java
autocmd FileType java nmap <leader>g :botright terminal java %<CR> :startinsert<CR>
autocmd FileType java setlocal nosmartindent nocindent expandtab
autocmd FileType java setlocal copyindent preserveindent tabstop=4 shiftwidth=4

"######################
"# Automatizar tareas #
"######################

" Auto-compilar software suckless
let g:terminal_cmd = '!$(which $TERMINAL) $TERMTITLE scratchpad $TERMEXEC sh -c'

" Función para ejecutar la compilación
autocmd BufWritePost config.def.h
			\ let subdir = fnamemodify(expand('%:p'), ':h:t') |
			\ if (subdir == 'dmenu' ||
			\     subdir == 'dwm' ||
			\     subdir == 'st' ||
			\     subdir == 'dwmblocks') |
			\ let cmd = g:terminal_cmd . ' "cd ' . expand('%:p:h') .
			\ '/; doas make clean install"' |
			\ if subdir == 'dwmblocks' |
			\ let cmd .= ' && killall dwmblocks; dwmblocks &' |
			\ endif |
			\ execute cmd |
			\ endif

au BufWritePost ~/.dotfiles/.config/dunst/dunstrc
			\ :!pkill dunst;
			\ dunst &;
			\ notify-send -i preferences-desktop-notification-bell "Dunst reiniciado"

" Borrar automaticamente los espacios sobrantes
au BufWritePre * let currPos = getpos(".")
au BufWritePre * %s/\s\+$//e
au BufWritePre * %s/\n\+\%$//e
au BufWritePre * cal cursor(currPos[1], currPos[2])

au BufWritePre * if &filetype == 'sh' | :Autoformat | endif
au BufWritePre * if &filetype == 'tex' | :Autoformat | endif
au BufWritePre * if &filetype == 'java' | :Autoformat | endif
