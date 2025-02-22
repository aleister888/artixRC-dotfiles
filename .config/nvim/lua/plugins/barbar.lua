return {
	"romgrk/barbar.nvim",
	dependencies = {
		"lewis6991/gitsigns.nvim",
		"nvim-tree/nvim-web-devicons",
	},
	init = function()
		vim.g.barbar_auto_setup = true
	end,
	opts = {
		animation = true, -- Mostrar animaciones
		-- Iconos para archivos rastreados por git
		gitsigns = {
			added = { enabled = true, icon = "+" },
			changed = { enabled = true, icon = "~" },
			deleted = { enabled = true, icon = "-" },
		},
		icons = {
			buffer_index = true, -- Mostrar pestañas numeradas
			button = " ", -- Icono para cerrar las pestañas
		},
		-- No mostrar pestaña para los buffers con este tipo de archivo
		exclude_ft = { "qf", "vimtex-toc", "undotree", "NvimTree" },
	},

	-- Mapeos para cambiar de pestaña
	vim.keymap.set("n", "<leader>1", "<Cmd>BufferGoto 1<CR>", { noremap = true, silent = true }),
	vim.keymap.set("n", "<leader>2", "<Cmd>BufferGoto 2<CR>", { noremap = true, silent = true }),
	vim.keymap.set("n", "<leader>3", "<Cmd>BufferGoto 3<CR>", { noremap = true, silent = true }),
	vim.keymap.set("n", "<leader>4", "<Cmd>BufferGoto 4<CR>", { noremap = true, silent = true }),
	vim.keymap.set("n", "<leader>5", "<Cmd>BufferGoto 5<CR>", { noremap = true, silent = true }),
	vim.keymap.set("n", "<leader>6", "<Cmd>BufferGoto 6<CR>", { noremap = true, silent = true }),
	vim.keymap.set("n", "<leader>7", "<Cmd>BufferGoto 7<CR>", { noremap = true, silent = true }),
	vim.keymap.set("n", "<leader>8", "<Cmd>BufferGoto 8<CR>", { noremap = true, silent = true }),
	vim.keymap.set("n", "<leader>9", "<Cmd>BufferGoto 9<CR>", { noremap = true, silent = true }),
	vim.keymap.set("n", "<leader>c", "<Cmd>BufferClose<CR>", { noremap = true, silent = true }),
	-- Mapeo para cerrar la pestaña actual
	vim.api.nvim_set_hl(0, "BufferTabpageFill", { bg = "#282828", fg = "#a89984" }),
}
