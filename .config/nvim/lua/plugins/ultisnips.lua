return {
	"Sirver/ultisnips",
	config = function()
		vim.g.UltiSnipsSnippetDirectories = { "~/.config/nvim/snips" }
		vim.g.UltiSnipsExpandTrigger = "<tab>"
		vim.g.UltiSnipsJumpForwardTrigger = "<tab>"
		vim.g.UltiSnipsJumpBackwardTrigger = "<M-tab>"
	end,
}
