return {
	"mfussenegger/nvim-jdtls",
	lazy = true,
	ft = "java",
	config = function()
		local jdtls = require("jdtls")
		local root_dir = vim.fs.dirname(vim.fs.find({
			".git",
			"pom.xml",
			"build.gradle",
			".project",
		}, { upward = true })[1])

		local config = {
			cmd = { vim.fn.expand("~/.local/share/nvim/mason/bin/jdtls") },
			root_dir = root_dir,
		}

		-- Inicia el servidor JDTLS
		jdtls.start_or_attach(config)
	end,
}
