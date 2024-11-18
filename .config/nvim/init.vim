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
	Plug 'cakebaker/scss-syntax.vim'
	Plug 'ryanoasis/vim-devicons' " Iconos
	Plug 'nvim-tree/nvim-web-devicons' " Iconos
	Plug 'LunarWatcher/auto-pairs' " Auto-cerrar: ( { [
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
	Plug 'neoclide/coc.nvim', {'branch': 'release'} " Sugerencias de entrada / autocompletado
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

" coc.nvim
let g:coc_disable_startup_warning = 1
let g:coc_global_extensions = [ 'coc-sh', 'coc-vimtex', 'coc-texlab' ]

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

function! CocStatus()
	return g:coc ? 'COC' : ''
endfunction
function! AutoPairsStatus()
	return g:pair ? '  {}' : ''
endfunction
function! TabStatus()
	return g:tab ? '  \t' : ''
endfunction
if $USER !=# 'root'
	let g:airline_section_x = airline#section#create(['%{CocStatus()}%{AutoPairsStatus()}%{TabStatus()}'])
endif

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
autocmd FileType * setlocal copyindent preserveindent tabstop=2 shiftwidth=2

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
nnoremap <silent><leader>t :NvimTreeToggle<CR>
nnoremap <silent><leader>u :UndotreeToggle<CR>

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
au Filetype tex nmap <silent><leader>f <plug>(vimtex-toc-toggle)<CR>
au Filetype tex nmap <leader>g :VimtexCompile<CR>
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

" Shell
au FileType sh nmap <leader>f :CocList outline<CR>

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

" Alternar como se visualizan las tabulaciones
	let g:tab = 1
	function! TabExp()
		if &tabstop == 2
			set tabstop=8
			set shiftwidth=8
		else
			set tabstop=2
			set shiftwidth=2
		endif
		let g:tab = !g:tab
	endfunction
inoremap <F3> <C-O>:call TabExp()<CR>
nnoremap <F3> :call TabExp()<CR>

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
