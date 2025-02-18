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

		-- Mapeo para ejecutar la clase actual con <leader>g
		vim.api.nvim_set_keymap("n", "<leader>g", ":lua RunJavaClass()<CR>", { noremap = true, silent = true })

		-- Función para ejecutar la clase Java actual
		function RunJavaClass()
			local file = vim.fn.expand("%:p") -- Ruta completa del archivo actual
			local src_dir = root_dir .. "/src"
			local bin_dir = root_dir .. "/bin"

			-- Asegurar que solo la parte después de src/ se usa como class_path
			local relative_path = file:sub(#src_dir + 2) -- Remover src/ (y la barra extra)
			local class_path = relative_path:gsub("%.java$", "") -- Remover la extensión .java

			local compile_cmd = string.format(
				"cd %s && mkdir -p %s && javac -d %s $(find src -name '*.java')",
				root_dir,
				bin_dir,
				bin_dir
			)
			local run_cmd = string.format("cd %s && java -cp %s %s", root_dir, bin_dir, class_path)

			-- Abrir una terminal en Neovim y ejecutar los comandos
			vim.cmd("botright split | resize 16 | term " .. compile_cmd .. " && " .. run_cmd)
		end
	end,
}
