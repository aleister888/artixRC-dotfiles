return {
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		build = "cd app && yarn install",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		ft = { "markdown" },
		config = function()
			-- Configuración del plugin markdown-preview.nvim
			vim.cmd([[
				function! OpenMarkdownPreview(url)
					silent! execute "!" . "setsid -f firefox --new-window " . shellescape(a:url, 1)
				endfunction
			]])
			vim.g.mkdp_auto_start = false
			vim.g.mkdp_refresh_slow = true
			vim.g.mkdp_page_title = vim.fn.expand("%:t") -- Usa el nombre del archivo actual
			vim.g.mkdp_browserfunc = "OpenMarkdownPreview" -- Usa la función que definimos arriba
			vim.g.mkdp_preview_options = { disable_filename = true }

			-- Mapeo para abrir la vista previa
			vim.keymap.set("n", "<leader>h", "<cmd>MarkdownPreview<CR>", { silent = true, noremap = true })
			-- Mapeos para italizar o hacer negrita
			vim.keymap.set("v", "*", 's*<C-r>"*', { noremap = true, silent = true })
			vim.keymap.set("v", "_", 's_<C-r>"_', { noremap = true, silent = true })
			vim.keymap.set("v", "<leader>*", 's**<C-r>"**', { noremap = true, silent = true })
			vim.keymap.set("v", "<leader>_", 's__<C-r>"__', { noremap = true, silent = true })
		end,
	},
	{
		"preservim/vim-markdown",
		ft = { "markdown" },
		config = function()
			vim.g.vim_markdown_folding_disabled = 1
			local function toc_toggle()
				-- Verifica si existe una ventana de lista local abierta
				local loclist = vim.fn.getloclist(0, { winid = 0 })
				if loclist.winid and loclist.winid ~= 0 then
					-- Si existe, cierra la ventana
					vim.cmd("lclose")
				else
					-- Si no existe, abre la vista TOC (Tabla de Contenidos)
					vim.cmd("Tocv")
				end
			end
			vim.keymap.set("n", "<leader>f", toc_toggle, { silent = true })
		end,
	},
}
