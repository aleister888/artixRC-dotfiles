require("bufferline").setup{
	options = {
		show_buffer_icons = true,
		show_buffer_close_icons = true,
		show_close_icon = true,
		buffer_close_icon = "",
		close_icon = "",
		tab_size = 10,
		diagnostics = "coc",
		diagnostics_indicator = function(count, level, diagnostics_dict, context)
			local s = ""
			for e, n in pairs(diagnostics_dict) do
				local sym = e == "error" and " " or (e == "warning" and " " or "")
				s = s .. sym
			end
			return s
		end,
		offsets = {
			{ filetype = "nerdtree",
				text = "Explorador de Archivos" },
			{ filetype = "vimtex-toc",
				text = "Índice" },
			{ filetype = "qf",
				text = "Índice" },
		},
		-- Excluir el TOC de Markdown
		custom_filter = function(bufnr)
			local exclude_ft = { "qf", "git" }
			local cur_ft = vim.bo[bufnr].filetype
			local should_filter = vim.tbl_contains(exclude_ft, cur_ft)
			if should_filter then
				return false
			end
			return true
		end,
	},
}
