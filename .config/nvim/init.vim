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
	Plug 'akinsho/bufferline.nvim' " Tabs

	Plug 'rrethy/vim-hexokinase', { 'do': 'make hexokinase' } " Pre-visualización de colores
	let g:Hexokinase_highlighters = [ 'backgroundfull' ]

	" Markdown
	Plug 'preservim/vim-markdown'
	let g:vim_markdown_folding_disabled = 1
	Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']} " Previews de markdown en local
	let g:mkdp_auto_start = 0
	let g:mkdp_preview_options = {
		\ 'mkit': {},
		\ 'katex': {},
		\ 'uml': {},
		\ 'maid': {},
		\ 'disable_sync_scroll': 0,
		\ 'sync_scroll_type': 'middle',
		\ 'hide_yaml_meta': 1,
		\ 'sequence_diagrams': {},
		\ 'flowchart_diagrams': {},
		\ 'content_editable': v:false,
		\ 'disable_filename': 0,
		\ 'toc': {}
		\ }
	function OpenMarkdownPreview (url)
		execute "silent ! setsid -f firefox --new-window " . a:url
	endfunction
	let g:mkdp_browserfunc = 'OpenMarkdownPreview'

	Plug 'sheerun/vim-polyglot' " Plugin para mejorar el resaltado de sintaxis
	Plug 'lervag/vimtex' " Sugerencias de entrada (laTeX)
	Plug 'neoclide/coc.nvim', {'branch': 'release'} " Sugerencias de entrada
	let g:coc_disable_startup_warning = 1
	let g:coc_global_extensions = [ 'coc-sh', 'coc-vimtex', 'coc-texlab' ]
	inoremap <silent><expr> <s-tab> pumvisible() ? coc#pum#confirm() : "\<C-g>u\<tab>"
	let g:coc_preferences = {
		\ 'suggest.maxCompleteItemCount': 50,
		\ 'suggest.detailField': 'menu',
		\ 'suggest.fixIncomplete': 1,
		\ 'coc.preferences.formatOnType': v:false,
		\ 'coc.preferences.formatOnSaveFiletypes': []
		\ }
	augroup my_coc_highlights
		au!
		au ColorScheme * highlight CocHighlightText gui=NONE guibg=#3C3836
		au ColorScheme * highlight CocHighlightRead gui=NONE guibg=#3C3836
		au ColorScheme * highlight CocHighlightWrite gui=NONE guibg=#3C3836
		au ColorScheme * highlight CocErrorSign guifg=#B16286
		au ColorScheme * highlight CocWarningSign guifg=#fabd2f
		au ColorScheme * highlight CocInfoSign guifg=#83a598
		au ColorScheme * highlight CocHintSign guifg=#8ec07c
		au ColorScheme * highlight CocErrorFloat guibg=#222222 guifg=#B16286
		au ColorScheme * highlight CocWarningFloat guibg=#222222 guifg=#fabd2f
		au ColorScheme * highlight CocInfoFloat guibg=#222222 guifg=#8ec07c
		au ColorScheme * highlight CocHintFloat guibg=#222222 guifg=#98971A
		au ColorScheme * highlight CocFloating guibg=#222222
		au ColorScheme * highlight CocMenuSel guibg=#3C3836
	augroup END

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


" Ajustes generales
syntax enable
set noexpandtab
set title encoding=UTF-8
set mouse=a scrolloff=10
set list hidden autochdir
set ttimeoutlen=0 wildmode=longest,list,full
set number relativenumber cursorline " Opciones del cursor
set ic | set ignorecase | set incsearch " Ajustes de búsqueda
set conceallevel=2
set clipboard+=unnamedplus " Ajustes de pantalla


" Tema de colores
set background=dark termguicolors
set fillchars+=vert:\  " Espacio como separadores
if $USER !=# 'root'
	colorscheme gruvbox
endif
let g:gruvbox_contrast_dark = "hard"
autocmd VimEnter * highlight Normal ctermbg=none guibg=none
autocmd VimEnter * highlight NonText ctermbg=none guibg=none
autocmd VimEnter * highlight LineNr ctermbg=none guibg=none
autocmd VimEnter * highlight Folded ctermbg=none guibg=none
if !has('gui_running')
	set t_Co=256
endif


" Atajos de teclado:


" Activar/Desactivar concealing
nnoremap <leader>c :exec &conceallevel == 0 ? "set conceallevel=2" : "set conceallevel=0"<CR>

" Shift+Enter para añadir una nueva linea sin identado (Markdown)
function! NoIndentNewline()
	call feedkeys("\<Esc>o\<C-u>", 'n')
endfunction
au Filetype markdown inoremap <S-CR> <Esc>:call NoIndentNewline()<CR>

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
au Filetype tex nmap <leader>f <plug>(vimtex-toc-toggle)<CR>
au Filetype tex nmap <leader>g :!arara % && notify-send -t 1500 "Compliación Exitosa"<CR><CR>
au Filetype tex nmap <leader>h :!setsid /usr/bin/zathura $(echo % \| sed 's/tex$/pdf/') <CR><CR>
au Filetype tex nmap <leader>j :!xelatex %<CR>

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
au Filetype markdown nmap <leader>h :MarkdownPreviewToggle<CR>

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

if $USER !=# 'root'
	so ~/.config/nvim/bufferline.lua
endif
