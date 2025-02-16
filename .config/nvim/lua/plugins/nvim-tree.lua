return {
	"nvim-tree/nvim-tree.lua",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("nvim-tree").setup({}) -- Asegura que nvim-tree se inicializa
		vim.keymap.set("n", "<leader>t", "<Cmd>NvimTreeToggle<CR>", { silent = true })
	end,
}
