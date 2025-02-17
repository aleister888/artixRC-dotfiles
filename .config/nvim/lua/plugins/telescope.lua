return {
	"nvim-telescope/telescope.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope-ui-select.nvim",
	},
	config = function()
		local telescope = require("telescope")

		-- Configuración básica de telescope
		telescope.setup({
			extensions = {
				["ui-select"] = {
					require("telescope.themes").get_dropdown({}),
				},
			},
		})

		-- Cargar la extensión ui-select
		telescope.load_extension("ui-select")

		-- Búsqueda de archivos con fzf
		vim.keymap.set("n", "<leader>T", function()
			require("telescope.builtin").find_files()
		end, { noremap = true, silent = true })
	end,
}
