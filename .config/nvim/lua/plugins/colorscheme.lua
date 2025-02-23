function SetColorscheme()
	vim.cmd.colorscheme("gruvbox")
	-- Cambiar el color de los números de línea
	vim.api.nvim_set_hl(0, "LineNr", { bg = "#282828", fg = "#a89984" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#282828", fg = "#a89984" })
end

return {
	"ellisonleao/gruvbox.nvim",
	priority = 1000,
	config = function()
		require("gruvbox").setup({
			transparent_mode = true,
			inverse = true,
		})
		SetColorscheme()
	end,
}
