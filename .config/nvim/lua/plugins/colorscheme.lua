function SetColorscheme()
	vim.cmd.colorscheme("gruvbox")
	-- Cambiar el color de los números de línea
	vim.api.nvim_set_hl(0, "LineNr", { bg = "#282828", fg = "#a89984" })
end

return {
	"ellisonleao/gruvbox.nvim",
	priority = 1000,
	config = function()
		require("gruvbox").setup({
			contrast = "hard",
			invert_selection = true,
			transparent_mode = true,
		})
		SetColorscheme()
	end,
}
