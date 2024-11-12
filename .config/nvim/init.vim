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

	Plug 'ryanoasis/vim-devicons' " Iconos
	Plug 'LunarWatcher/auto-pairs' " Auto-cerrar: ( { [
	Plug 'morhetz/gruvbox' " Tema

	Plug 'akinsho/bufferline.nvim' " Pestañas

	Plug 'preservim/nerdtree' " Árbol de directorios
	let NERDTreeShowHidden=1
	nnoremap <silent><leader>t :NERDTreeToggle<CR>
	let g:NERDTreeDirArrowExpandable="+"
	let g:NERDTreeDirArrowCollapsible="-"
	set laststatus=3 " Mostar solo una barra de estado a la vez
	au BufWinEnter * if &filetype == 'nerdtree' | setlocal winhighlight=StatusLineNC | endif
	au BufWinLeave * if &filetype == 'nerdtree' | setlocal winhighlight= | endif

	" Pre-visualización de colores
	Plug 'rrethy/vim-hexokinase', { 'do': 'make hexokinase' }
	let g:Hexokinase_highlighters = [ 'backgroundfull' ]

	" Mostrar árbol de cambios
	Plug 'mbbill/undotree'
	nnoremap <leader>u :UndotreeToggle<CR>

	" Markdown
	Plug 'preservim/vim-markdown'
	let g:vim_markdown_toc_autofit = 1
	let g:vim_markdown_folding_disabled = 1
	let g:vim_markdown_auto_insert_bullets = 0
	let g:vim_markdown_new_list_item_indent = 0
	let g:vim_markdown_syntax = 'on'
	let g:vim_markdown_math = 1
	" Previews para Markdown
	Plug 'iamcco/markdown-preview.nvim', {
		\ 'do': { -> mkdp#util#install() },
		\ 'for': ['markdown', 'vim-plug'] }
	let g:mkdp_auto_start = 0
	let g:mkdp_preview_options = { 'disable_filename': 1 }
	function OpenMarkdownPreview (url)
		execute "silent ! setsid -f firefox --new-window " . a:url
	endfunction
	let g:mkdp_browserfunc = 'OpenMarkdownPreview'
	let g:mkdp_page_title = '${name}'

	Plug 'lervag/vimtex' " Sugerencias de entrada (laTeX)
	let g:vimtex_toc_config = { 'show_help': 0 }

	" Sugerencias de entrada / autocompletado
	Plug 'neoclide/coc.nvim', {'branch': 'release'}
	let g:coc_disable_startup_warning = 1
	let g:coc_global_extensions = [ 'coc-sh', 'coc-vimtex', 'coc-texlab' ]
	inoremap <silent><expr> <s-tab> pumvisible() ? coc#pum#confirm() : "\<C-g>u\<tab>"

	" Ajustes generales para Coc
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

	" Configurar los colores de Coc
	augroup colorscheme-overrides
		au!
		au ColorScheme * hi CocErrorSign guifg=#B16286
		au ColorScheme * hi CocWarningSign guifg=#fabd2f
		au ColorScheme * hi CocInfoSign guifg=#83a598
		au ColorScheme * hi CocHintSign guifg=#8ec07c
		au ColorScheme * hi CocFloating guibg=#282828
		au ColorScheme * hi CocMenuSel guibg=#3C3836
		au ColorScheme * hi CocErrorHighlight gui=underline guifg=#D5C4A1 guibg=#282828
		au ColorScheme * hi CocUnusedHighlight gui=underline guifg=#D5C4A1 guibg=#282828
		au ColorScheme * hi CocWarningHighlight gui=underline guifg=#D5C4A1 guibg=#282828
		au ColorScheme * hi CocInfoHighlight gui=underline guifg=#D5C4A1 guibg=#282828
	augroup END

	Plug 'sirver/ultisnips' " Snippets
	let g:UltiSnipsSnippetDirectories = ['~/.config/nvim/snips']
	let g:UltiSnipsExpandTrigger = '<tab>'
	let g:UltiSnipsJumpForwardTrigger = '<tab>'
	let g:UltiSnipsJumpBackwardTrigger = '<M-tab>'

	Plug 'vim-airline/vim-airline' " Barra de estado
	Plug 'vim-airline/vim-airline-themes'
	let g:airline_theme = 'monochrome'
	let g:airline_symbols = {}
	let g:airline_symbols.branch = '   '
	let g:airline_symbols.readonly = '󰌾 '
	let g:airline_symbols.linenr = '   '
	let g:airline_symbols.maxlinenr = '   '
	let g:airline_symbols.dirty = '  '
	let g:airline_symbols.colnr = ' C:'

	call plug#end()
endif


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
if $USER !=# 'root'
	let g:airline_section_x = airline#section#create(['%{CocStatus()}%{AutoPairsStatus()}%{TabStatus()}'])
endif

" Activar resaltado de sintáxis
syntax enable

" Desactivar el convenio de indentación especifico del tipo de archivo
autocmd FileType * setlocal noautoindent nosmartindent nocindent
autocmd FileType * setlocal noexpandtab copyindent preserveindent
autocmd FileType * setlocal tabstop=2 shiftwidth=2

set title encoding=UTF-8
set mouse=a scrolloff=0 nowrap
set list hidden autochdir
set fillchars+=vert:\|
set listchars=tab:\|\ ,trail:·,lead:·,precedes:<,extends:>
set ttimeoutlen=0 wildmode=longest,list,full
set pumheight=10 " coc.vim solo podrá mostar 10 sugerencias

set number relativenumber cursorline " Opciones del cursor
set ignorecase incsearch " Ajustes de búsqueda

" Desactivar el Portapapeles si ejecutamos nvim como root
if $USER !=# 'root'
	set clipboard+=unnamedplus " Portapapeles
endif

set lazyredraw " No re-dibujar mientras se ejecutan macros

" Expander código en modo insert
set conceallevel=2
autocmd InsertEnter * set conceallevel=0

" Desactivar backups
set nobackup
set nowb
set noswapfile

" Tema de colores
set background=dark termguicolors

if $USER !=# 'root'
	colorscheme gruvbox
endif

autocmd VimEnter * |
	\ hi Search guifg=#282828 guibg=#D5C4A1 |
	\ hi IncSearch guifg=#282828 guibg=#D3869B |
	\ hi CurSearch guifg=#83A598 guibg=#282828 |
	\ hi Normal ctermbg=none guibg=none |
	\ hi NonText ctermbg=none guibg=none |
	\ hi LineNr ctermbg=none guibg=none |
	\ hi Folded ctermbg=none guibg=none |
	\ hi SpellBad guifg=#8EC07C guibg=#282828 |
	\ hi SpellCap guifg=#8EC07C guibg=#282828 |
	\ hi SpellLocal guifg=#FABD2F guibg=#282828 |
	\ hi SpellRare guifg=#FE8019 guibg=#282828

if !has('gui_running')
	set t_Co=256
endif


" Atajos de teclado:


" Contraer o expandir expresiones/text
nnoremap <leader>c :let &conceallevel = (&conceallevel == 0 ? 2 : 0)<CR>
nnoremap <leader>v :set wrap!<CR>

" Desplazarse por el texto
nnoremap <ScrollWheelUp> kzz<C-G>
nnoremap <ScrollWheelDown> jzz<C-G>
nnoremap <C-ScrollWheelUp> 5kzz<C-G>
nnoremap <C-ScrollWheelDown> 5jzz<C-G>
nnoremap <C-Up> 5kzz<C-G>
nnoremap <C-Down> 5jzz<C-G>
nnoremap = $<C-G>
nnoremap G :$<CR><C-G>zz
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

" TeX
au Filetype tex nmap <leader>f <plug>(vimtex-toc-toggle)<CR>
au Filetype tex nmap <leader>g :!arara % && notify-send -t 1500 "Compliación Exitosa"<CR><CR>
au Filetype tex nmap <leader>h :!setsid /usr/bin/zathura $(echo % \| sed 's/tex$/pdf/') <CR><CR>
au Filetype tex nmap <leader>j :!xelatex %<CR>

" Markdown
" https://github.com/preservim/vim-markdown/issues/356#issuecomment-617365622
function s:TocToggle()
	if index(["markdown", "qf"], &filetype) == -1
		return
	endif
	if get(getloclist(0, {'winid':0}), 'winid', 0)
		lclose
	else
		Tocv
	endif
endfunction
command TocToggle call s:TocToggle()
au FileType markdown nmap <leader>f :TocToggle<CR>
au Filetype markdown nmap <leader>h :MarkdownPreview<CR>

" Shell
au FileType sh nmap <leader>f :CocList outline<CR>

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

" Activar/Desactivar comprobación ortografía
inoremap <silent><F3> <C-O>:setlocal spell! spelllang=es_es<CR>
inoremap <silent><F4> <C-O>:setlocal spell! spelllang=en_us<CR>
nnoremap <silent><F3> :setlocal spell! spelllang=es_es<CR>
nnoremap <silent><F4> :setlocal spell! spelllang=en_us<CR>

" Alternar como se visualizan las tabulaciones
let g:tab = 1
set tabstop=2
set shiftwidth=2
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
inoremap <F5> <C-O>:call TabExp()<CR>
nnoremap <F5> :call TabExp()<CR>

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

if $USER !=# 'root'
	so ~/.config/nvim/bufferline.lua
endif
