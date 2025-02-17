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
			vim.cmd([[
			function! OpenMarkdownPreview(url)
				silent! execute "!" . "firefox --new-window " . shellescape(a:url, 1)
			endfunction
			]])

			vim.g.mkdp_auto_start = false
			vim.g.mkdp_refresh_slow = true
			vim.g.mkdp_page_title = vim.fn.expand("%:t") -- Usa el nombre del archivo actual
			vim.g.mkdp_browserfunc = "OpenMarkdownPreview" -- Usa la función que definimos arriba
			vim.g.mkdp_preview_options = { disable_filename = true }

			-- Mapeo de teclas para abrir la vista previa
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "markdown",
				callback = function()
					vim.keymap.set("n", "<leader>h", "<cmd>MarkdownPreview<CR>", { silent = true, noremap = true })
				end,
			})
		end,
	},
}
