return {
	"rcarriga/nvim-notify",
	config = function()
		vim.notify = require("notify")
		require("notify").setup({
			background_colour = "#ebdbb2",
		})
	end,
}
