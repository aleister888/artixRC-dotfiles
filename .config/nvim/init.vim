" Auto-instalar vim-plug
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
	silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
	autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif


let mapleader = "," " Definir la tecla leader


" Cargar plugins
if $USER !=# 'root'
	call plug#begin('~/.local/share/nvim/plugged')

	Plug 'ryanoasis/vim-devicons' " Iconos
	Plug 'LunarWatcher/auto-pairs' " Auto-cerrar: ( { [
	Plug 'morhetz/gruvbox' " Tema
	let g:indentLine_enabled = 1

	Plug 'akinsho/bufferline.nvim' " Pestañas

	Plug 'preservim/nerdtree' " Árbol de directorios
	let NERDTreeShowHidden=1
	nnoremap <silent><leader>t :NERDTreeToggle<CR>
	let g:NERDTreeDirArrowExpandable="+"
	let g:NERDTreeDirArrowCollapsible="~"
	set laststatus=3 " Mostar solo una barra de estado a la vez
	au BufWinEnter * if &filetype == 'nerdtree' | setlocal winhighlight=StatusLineNC | endif
	au BufWinLeave * if &filetype == 'nerdtree' | setlocal winhighlight= | endif

	Plug 'rrethy/vim-hexokinase', { 'do': 'make hexokinase' } " Pre-visualización de colores
	let g:Hexokinase_highlighters = [ 'backgroundfull' ]

	" Mejorar el deshacer cambios
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
	Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']} " Previews de markdown en local
	let g:mkdp_auto_start = 0
	let g:mkdp_preview_options = { 'disable_filename': 1 }
	function OpenMarkdownPreview (url)
		execute "silent ! setsid -f firefox --new-window " . a:url
	endfunction
	let g:mkdp_browserfunc = 'OpenMarkdownPreview'
	let g:mkdp_page_title = '${name}'

	Plug 'lervag/vimtex' " Sugerencias de entrada (laTeX)
	let g:vimtex_toc_config = { 'show_help': 0 }

	Plug 'neoclide/coc.nvim', {'branch': 'release'} " Sugerencias de entrada
	let g:coc_disable_startup_warning = 1
	let g:coc_global_extensions = [ 'coc-sh', 'coc-vimtex', 'coc-texlab' ]
	inoremap <silent><expr> <s-tab> pumvisible() ? coc#pum#confirm() : "\<C-g>u\<tab>"
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
		au ColorScheme * highlight CocErrorSign guifg=#B16286
		au ColorScheme * highlight CocWarningSign guifg=#fabd2f
		au ColorScheme * highlight CocInfoSign guifg=#83a598
		au ColorScheme * highlight CocHintSign guifg=#8ec07c
		au ColorScheme * highlight CocFloating guibg=#282828
		au ColorScheme * highlight CocMenuSel guibg=#3C3836
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
set mouse=a scrolloff=10
set list hidden autochdir
set listchars=tab:\|\ ,trail:·,lead:·,precedes:<,extends:>
set ttimeoutlen=0 wildmode=longest,list,full
set nowrap
set pumheight=10 " coc.vim solo podrá mostar 10 sugerencias

set number relativenumber cursorline " Opciones del cursor
set ignorecase incsearch " Ajustes de búsqueda

" Desactivar el Portapapeles si ejecutamos nvim como root
if $USER !=# 'root'
	set clipboard+=unnamedplus " Portapapeles
endif

set lazyredraw " No re-dibujar mientras se ejecutan macros

" Expander código en modo insert y contraerlo en modo normal
set conceallevel=2
augroup vimrc
	autocmd!
	autocmd InsertEnter * set conceallevel=0
	autocmd InsertLeave * set conceallevel=2
augroup END

" Desactivar backups
set nobackup
set nowb
set noswapfile

" Tema de colores
set background=dark termguicolors
set fillchars+=vert:+ " Espacio como separadores
if $USER !=# 'root'
	colorscheme gruvbox
endif
autocmd VimEnter * highlight Search guifg=#282828 guibg=#D5C4A1
autocmd VimEnter * highlight IncSearch guifg=#282828 guibg=#D3869B
autocmd VimEnter * highlight CurSearch guifg=#83A598 guibg=#282828
autocmd VimEnter * highlight Normal ctermbg=none guibg=none
autocmd VimEnter * highlight NonText ctermbg=none guibg=none
autocmd VimEnter * highlight LineNr ctermbg=none guibg=none
autocmd VimEnter * highlight Folded ctermbg=none guibg=none
if !has('gui_running')
	set t_Co=256
endif


" Atajos de teclado:


" Encapsular texto seleccionado
vnoremap " s"<C-r>""
vnoremap ' s'<C-r>"'
vnoremap ` s`<C-r>"`
vnoremap $ s$<C-r>"$
vnoremap ( s(<C-r>")
vnoremap { s{<C-r>"}
vnoremap [ s[<C-r>"]
vnoremap _ s_<C-r>"_
vnoremap <leader>_ s__<C-r>"__

" Activar/Desactivar comprobación ortografía
inoremap <silent><F3> <C-O>:setlocal spell! spelllang=es_es<CR>
inoremap <silent><F4> <C-O>:setlocal spell! spelllang=en_us<CR>
nnoremap <silent><F3> :setlocal spell! spelllang=es_es<CR>
nnoremap <silent><F4> :setlocal spell! spelllang=en_us<CR>

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

" Activar/Desactivar wrapping
inoremap <F6> <C-O>:set wrap!<CR>
nnoremap <F6> :set wrap!<CR>

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
