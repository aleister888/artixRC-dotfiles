" Auto-instalar vim-plug
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
	silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
	autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Plugins
call plug#begin('~/.local/share/nvim/plugged')

" Auto-cerrar llaves, paréntesis, ...
Plug 'LunarWatcher/auto-pairs'
function! MoveCursorLeftIfNeeded()
	let col = col('.')
	if col > 1
		call feedkeys("\<C-Left>")
	endif
endfunction

" Presionando ,, vamos al princio del patrón que queremos sustituir
let mapleader = ","
nnoremap <leader>, :call MoveCursorLeftIfNeeded()<CR>
" Si presionamos ahora ,+",',(,\,[,{ rodeamos la palabra por los limitadores
" deseados (Para no tener que desacrivar auto-pairs para poner limites a palabras ya escritas)
nnoremap <leader>" :s/\%#\([^[:space:]]\+\)/"\1"/g<CR>:noh<CR>
nnoremap <leader>' :s/\%#\([^[:space:]]\+\)/'\1'/g<CR>:noh<CR>
nnoremap <leader>( :s/\%#\([^[:space:]]\+\)/(\1)/g<CR>:noh<CR>
nnoremap <leader>\ :s/\%#\([^[:space:]]\+\)/\\(\1\\)/g<CR>:noh<CR>
nnoremap <leader>[ :s/\%#\([^[:space:]]\+\)/[\1]/g<CR>:noh<CR>
nnoremap <leader>{ :s/\%#\([^[:space:]]\+\)/{\1}/g<CR>:noh<CR>
nnoremap <leader>$ :s/\%#\([^[:space:]]\+\)/$\1$/g<CR>:noh<CR>

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
nnoremap <leader>t :NERDTreeToggle<CR>
let NERDTreeShowHidden=1
" Customizar NERDTree con el esquema de colores Gruvbox
autocmd vimenter * highlight NERDTreeDir guifg=#8ec07c
autocmd vimenter * highlight NERDTreeDirSlash guifg=#8ec07c
autocmd vimenter * highlight NERDTreeOpenable guifg=#83a598
autocmd vimenter * highlight NERDTreeClosable guifg=#83a598
autocmd vimenter * highlight NERDTreeExecFile guifg=#b8bb26
autocmd vimenter * highlight NERDTreeCWD guifg=#fabd2f

" Snippets
Plug 'sirver/ultisnips'
let g:UltiSnipsSnippetDirectories = ['~/.config/nvim/snips']
let g:UltiSnipsExpandTrigger = '<tab>'
let g:UltiSnipsJumpForwardTrigger = '<tab>'
let g:UltiSnipsJumpBackwardTrigger = '<M-tab>'

" Barra de estado
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Ajustes de airline
let g:airline_theme = 'gruvbox'
let g:airline_powerline_fonts = 0
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols = {}
let g:airline_symbols.branch = '   '
let g:airline_symbols.readonly = '   '
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


call plug#end()

" Opciones de vim
syntax enable
set title
set clipboard+=unnamedplus
set number relativenumber
set hidden
set ttimeoutlen=0
set ic
set ignorecase
set smartcase
set mouse=a
set noshowmode
set encoding=UTF-8
set wildmode=longest,list,full
set autochdir
set cursorline
set incsearch
set scrolloff=10
set list

" Tema de colores
set background=dark
set termguicolors
colorscheme gruvbox
hi Normal guibg=NONE ctermbg=NONE
if !has('gui_running')
	set t_Co=256
endif

" Activar/Desactivar sugerencias de entrada
inoremap <F1> <C-O>:call CocToggle()<CR>
nnoremap <F1> :call CocToggle()<CR>
" Comprobar ortografía
inoremap <F3> <C-O>:setlocal spell! spelllang=es_es<CR>
inoremap <F4> <C-O>:setlocal spell! spelllang=en_us<CR>
nnoremap <F3> :setlocal spell! spelllang=es_es<CR>
nnoremap <F4> :setlocal spell! spelllang=en_us<CR>
" Activar/Desactivar auto-cerrado de llaves, paréntesis, ...
inoremap <F5> <C-O>:AutoPairsToggle<CR>
nnoremap <F5> :AutoPairsToggle<CR>

" Sugerencias de entrada (Configuración)
let g:coc = 0

function! CocToggle()
	if g:coc
		CocEnable
		let g:coc = 0
	else
		CocDisable
		let g:coc = 1
	endif
endfunction

" Automatizar tareas cuando se escribe en un archivo
autocmd BufWritePost ~/.dotfiles/dwmblocks/blocks.h !$(which $TERMINAL) $TERMTITLE scratchpad $TERMEXEC sh -c 'cd ~/.dotfiles/dwmblocks/; doas make install' && pkill dwmblocks; dwmblocks &
autocmd BufWritePost ~/.dotfiles/dwm/config.h !$(which $TERMINAL) $TERMTITLE scratchpad $TERMEXEC sh -c 'cd ~/.dotfiles/dwm/; doas make install'
autocmd BufWritePost ~/.dotfiles/dmenu/config.h !$(which $TERMINAL) $TERMTITLE scratchpad $TERMEXEC sh -c 'cd ~/.dotfiles/dmenu/; doas make install'
autocmd BufWritePost ~/.dotfiles/st/config.h !$(which $TERMINAL) $TERMTITLE scratchpad $TERMEXEC sh -c 'cd ~/.dotfiles/st/; doas make install'
autocmd BufWritePost ~/.dotfiles/.config/dunst/dunstrc :!pkill dunst; dunst &

" LaTeX
" Compilar archivo de texto a PDF
autocmd Filetype tex map <M-g> :! arara % && notify-send "Document Compiled" <CR><CR>
autocmd Filetype tex map <M-S-g> :! xelatex % <CR>
" Abrir PDF resultante en un visór de documentos
autocmd Filetype tex map <M-h> :! setsid /usr/bin/zathura $(echo % \| sed 's/tex$/pdf/') <CR><CR>

" Groff
" Compilar documento Groff en un PDF
autocmd Filetype groff map <M-g> :! groff -ms % -T pdf > $(echo % \| sed 's/ms$/pdf/') <CR><CR>
" Compilar documento Groff en un PDF (Con imágenes)
autocmd FIletype groff map <M-S-g> :! groff -ms % -Tps > $(echo % \| sed 's/ms$/ps/'); time ps2pdf $(echo % \| sed 's/ms$/ps/') <CR>
" Pre-procesar con pic y compilar documento Groff en un PDF
autocmd Filetype groff map <C-g> :! pic % \| groff -ms -Tpdf > $(echo % \| sed 's/ms$/pdf/') <CR>
" Pre-procesar con pic y compilar documento Groff en un PDF (Con imágenes)
autocmd Filetype groff map <C-S-g> :! pic % \|  groff -ms -Tps > $(echo % \| sed 's/ms$/ps/'); time ps2pdf $(echo % \| sed 's/ms$/ps/') <CR>
" Abrir PDF resultante en un visór de documentos
autocmd Filetype groff map <M-w> :! $(echo % \| sed 's/ms$/pdf/') <CR><CR>

" C
autocmd Filetype c map <M-g> :! gcc % -o $(echo % \| sed 's/.c$//') -lm <CR>
autocmd Filetype c map <M-h> :terminal $PWD/$(echo % \| sed 's/.c$//')<CR>

" Ayuda
map <M-S-h> :echo "\n F1                Activar/Desactivar Sugestiones\n"
	\ . " F2                Activar/Desactivar Vista de Carpetas\n"
	\ . " F3                Activar Correciones (Español)\n"
	\ . " F4                Activar Correciones (Inglés)\n"
	\ . " F5                Desactivar/Activar Auto-Cerrado (LLaves, paréntesis, ...)\n"
	\ . " 'z'+'='           Corregir Palabra\n\n"
	\ . " laTeX:\n"
	\ . " LAlt + G          Compliar Documento (arara)\n"
	\ . " LAlt + Shift + G  Compliar Documento (xelatex)\n"
	\ . " LAlt + H          Abrir Documento\n\n"
	\ . " Groff:\n"
	\ . " LAlt + G          Compilar Documento (Sólo Texto)\n"
	\ . " LAlt + Shift + G  Compilar Documento (Con Imágenes)\n"
	\ . " Ctrl + G          Compilar Documento (Preprocesar con Pic)\n"
	\ . " Ctrl + Shift + G  Compliar Documento (Preprocesar con Pic, con Imágenes)\n"
	\ . " LAlt + H          Abrir Documento\n\n"
	\ . " C:\n"
	\ . " LAlt + G          Compilar con gcc\n"
	\ . " LAlt + H          Ejecutar en terminal\n"<CR>

" Auto acentuar caracteres con groff
" a
autocmd Filetype groff inoremap á  \['a] | autocmd Filetype groff inoremap Á  \['A]
autocmd Filetype groff inoremap â  \[^a] | autocmd Filetype groff inoremap Â  \[^A]
autocmd Filetype groff inoremap ä  \[:a] | autocmd Filetype groff inoremap Ä  \[:A]
" e
autocmd Filetype groff inoremap é  \['e] | autocmd Filetype groff inoremap É  \['E]
autocmd Filetype groff inoremap ê  \[^e] | autocmd Filetype groff inoremap Ê  \[^E]
autocmd Filetype groff inoremap ë  \[:e] | autocmd Filetype groff inoremap Ë  \[:E]
" i
autocmd Filetype groff inoremap í  \['i] | autocmd Filetype groff inoremap Í  \['I]
autocmd Filetype groff inoremap î  \[^i] | autocmd Filetype groff inoremap Î  \[^I]
autocmd Filetype groff inoremap ï  \[:i] | autocmd Filetype groff inoremap Ï  \[:I]
" o
autocmd Filetype groff inoremap ó  \['o] | autocmd Filetype groff inoremap Ó  \['O]
autocmd Filetype groff inoremap ô  \[^o] | autocmd Filetype groff inoremap Ô  \[^O]
autocmd Filetype groff inoremap ö  \[:o] | autocmd Filetype groff inoremap Ö  \[:O]
" u
autocmd Filetype groff inoremap ú  \['u] | autocmd Filetype groff inoremap Ú  \['U]
autocmd Filetype groff inoremap û  \[^u] | autocmd Filetype groff inoremap Û  \[^U]
autocmd Filetype groff inoremap ü  \[:u] | autocmd Filetype groff inoremap Ü  \[:U]
" Español
autocmd Filetype groff inoremap ñ  \[~n] | autocmd Filetype groff inoremap Ñ  \[~N]
autocmd Filetype groff inoremap ç  \[,c] | autocmd Filetype groff inoremap Ç  \[,C]
" Matemáticas
autocmd Filetype groff inoremap ·  \[pc] | autocmd Filetype groff inoremap ×  \[mu]
