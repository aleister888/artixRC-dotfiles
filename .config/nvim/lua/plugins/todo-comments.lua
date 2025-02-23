return {
	"folke/todo-comments.nvim",
	dependencies = "nvim-lua/plenary.nvim",
	config = true,
	init = function()
		require("todo-comments").setup({
			highlight = {
				multiline = true, -- Resalta comentarios multilinea
				pattern = [[.*<(KEYWORDS)\s*:?]], -- Patrón para detectar palabras clave
			},
		})
	end,
}
