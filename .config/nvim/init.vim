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

	Plug 'elkowar/yuck.vim' " Soporte para el lenguaje yuck
	Plug 'andis-sprinkis/lf-vim' " Soporte para el archivo de configuración de lf
	Plug 'alisdair/vim-armasm' " Sintaxis para ARM Assembly
	Plug 'cakebaker/scss-syntax.vim'
	Plug 'ryanoasis/vim-devicons' " Iconos
	Plug 'nvim-tree/nvim-web-devicons' " Iconos
	Plug 'morhetz/gruvbox' " Tema
	Plug 'akinsho/bufferline.nvim' " Pestañas
	Plug 'nvim-tree/nvim-tree.lua' " Árbol de directorios
	Plug 'rrethy/vim-hexokinase', { 'do': 'make hexokinase' } " Pre-visualización de colores
	Plug 'mbbill/undotree' " Mostrar árbol de cambios
	Plug 'preservim/vim-markdown' " Funciones para markdown
	Plug 'iamcco/markdown-preview.nvim', {
		\ 'do': { -> mkdp#util#install() },
		\ 'for': ['markdown', 'vim-plug'] } " Previews para Markdown
	Plug 'lervag/vimtex' " Sugerencias de entrada (laTeX)
	Plug 'sirver/ultisnips' " Snippets
	Plug 'vim-airline/vim-airline' " Barra de estado
	Plug 'vim-airline/vim-airline-themes'

	call plug#end()
endif

"################################
"# Configuración de los plugins #
"################################

" vim-armasm
let asmsyntax='armasm'
let filetype_inc='armasm'

" vim-hexokinase
let g:Hexokinase_highlighters = [ 'backgroundfull' ]

" vim-markdown
let g:vim_markdown_toc_autofit = 1
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_auto_insert_bullets = 0
let g:vim_markdown_new_list_item_indent = 0
let g:vim_markdown_syntax = 'on'
let g:vim_markdown_math = 1

" markdown-preview.nvim
let g:mkdp_auto_start = 0
let g:mkdp_refresh_slow = 1
let g:mkdp_preview_options = { 'disable_filename': 1 }
let g:mkdp_browserfunc = 'OpenMarkdownPreview'
let g:mkdp_page_title = '${name}'

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

" vim-airline
let g:airline_theme = 'monochrome'
let g:airline_symbols = {}
let g:airline_symbols.branch = '   '
let g:airline_symbols.readonly = '󰌾 '
let g:airline_symbols.linenr = '   '
let g:airline_symbols.maxlinenr = '   '
let g:airline_symbols.dirty = '  '
let g:airline_symbols.colnr = ' C:'

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

"#####################
"# Atajos de teclado #
"#####################

" Plugins
nnoremap <silent><leader>t :NvimTreeToggle<CR>
nnoremap <silent><leader>u :UndotreeToggle<CR>

" Abrir el mismo buffer en vertical/horizontal
nnoremap <leader>v :vsplit %<CR>
nnoremap <leader>h :split %<CR>

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

"######################
"# Automatizar tareas #
"######################

" Auto-compilar software suckless
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

" Borrar automaticamente los espacios sobrantes
autocmd BufWritePre * let currPos = getpos(".")
autocmd BufWritePre * %s/\s\+$//e
autocmd BufWritePre * %s/\n\+\%$//e
autocmd BufWritePre * cal cursor(currPos[1], currPos[2])
