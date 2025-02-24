return {
	"nanozuki/tabby.nvim",
	dependencies = "nvim-tree/nvim-web-devicons",
	config = function()
		vim.o.showtabline = 2
		require("tabby").setup({})
	end,

	-- Crear y cerrar pestañas
	vim.api.nvim_set_keymap("n", "<leader>at", ":$tabnew<CR>", { noremap = true }),
	vim.api.nvim_set_keymap("n", "<leader>c", ":tabclose<CR>", { noremap = true }),

	-- Cambiar a la pestaña anterior
	vim.api.nvim_set_keymap("n", "<leader>n", ":tabp<CR>", { noremap = true }),
	-- Cambiar a la pestaña anterior
	vim.api.nvim_set_keymap("n", "<leader>m", ":tabn<CR>", { noremap = true }),

	-- Mover a la pestaña anterior
	vim.api.nvim_set_keymap("n", "<leader>N", ":-tabmove<CR>", { noremap = true }),
	-- Mover a la pestaña siguiente
	vim.api.nvim_set_keymap("n", "<leader>M", ":+tabmove<CR>", { noremap = true }),
}
