return {
	"akinsho/bufferline.nvim",
	config = function()
		-- Configuración de Bufferline
		require("bufferline").setup({
			options = {
				show_buffer_icons = true,
				show_buffer_close_icons = false,
				show_close_icon = false,
				diagnostics = "nvim_lsp",
				diagnostics_indicator = function(count, level, diagnostics_dict, context)
					local s = ""
					for e, n in pairs(diagnostics_dict) do
						local sym = e == "error" and " " or (e == "warning" and " " or " ")
						s = s .. sym
					end
					return s
				end,
				offsets = {
					{ filetype = "qf", text = "Índice", separator = true },
					{ filetype = "vimtex-toc", text = "Índice", separator = true },
					{ filetype = "undotree", text = "Cambios", separator = true },
					{ filetype = "NvimTree", text = "Archivos", separator = true, highlight = "Directory" },
				},
				-- Excluir el TOC de Markdown
				custom_filter = function(bufnr)
					local exclude_ft = { "qf", "git" }
					local cur_ft = vim.bo[bufnr].filetype
					local should_filter = vim.tbl_contains(exclude_ft, cur_ft)
					if should_filter then
						return false
					end
					return true
				end,
			},
		})

		-- Mapeo de teclas para Bufferline
		vim.keymap.set("n", "<leader>1", "<Cmd>BufferLineGoToBuffer 1<CR>", { silent = true })
		vim.keymap.set("n", "<leader>2", "<Cmd>BufferLineGoToBuffer 2<CR>", { silent = true })
		vim.keymap.set("n", "<leader>3", "<Cmd>BufferLineGoToBuffer 3<CR>", { silent = true })
		vim.keymap.set("n", "<leader>4", "<Cmd>BufferLineGoToBuffer 4<CR>", { silent = true })
		vim.keymap.set("n", "<leader>5", "<Cmd>BufferLineGoToBuffer 5<CR>", { silent = true })
		vim.keymap.set("n", "<leader>6", "<Cmd>BufferLineGoToBuffer 6<CR>", { silent = true })
		vim.keymap.set("n", "<leader>7", "<Cmd>BufferLineGoToBuffer 7<CR>", { silent = true })
		vim.keymap.set("n", "<leader>8", "<Cmd>BufferLineGoToBuffer 8<CR>", { silent = true })
		vim.keymap.set("n", "<leader>9", "<Cmd>BufferLineGoToBuffer 9<CR>", { silent = true })
		vim.keymap.set("n", "<leader>c", ":bp <BAR> bd #<CR>", { noremap = true, silent = true })
	end,
}
