return {
	"brenoprata10/nvim-highlight-colors",
	event = { "BufReadPost", "BufWritePost" },
	config = function()
		require("nvim-highlight-colors").setup({})
	end,
}
