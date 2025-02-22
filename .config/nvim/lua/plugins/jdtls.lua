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

		-- Depuración
		local bundles = {
			vim.fn.glob(
				vim.env.HOME .. "/.local/share/nvim/mason/share/java-debug-adapter/com.microsoft.java.debug.plugin.jar"
			),
		}
		vim.list_extend(
			bundles,
			vim.split(vim.fn.glob(vim.env.HOME .. "/.local/share/nvim/mason/share/java-test/*.jar", 1), "\n")
		)
		vim.list_extend(
			bundles,
			vim.split(
				vim.fn.glob(
					vim.env.HOME .. "/.local/share/nvim/mason/packages/java-debug-adapter/extension/server/*.jar",
					1
				),
				"\n"
			)
		)

		local config = {
			cmd = {
				vim.fn.expand("$HOME/.local/share/nvim/mason/bin/jdtls"),
				("--jvm-arg=-javaagent:%s"):format(
					vim.fn.expand("$HOME/.local/share/nvim/mason/packages/jdtls/lombok.jar")
				),
			},
			root_dir = root_dir,
			capabilities = require("cmp_nvim_lsp").default_capabilities(),
			init_options = {
				bundles = bundles,
			},
		}

		-- Inicia el servidor JDTLS
		jdtls.start_or_attach(config)

		vim.keymap.set("n", "<leader>g", ":lua RunJavaClass()<CR>", { noremap = true, silent = true })
		vim.keymap.set("n", "<leader>jd", ":lua DocJavaClass()<CR>", { noremap = true, silent = true })
		vim.keymap.set("n", "<leader>jD", ":lua OpenJavaDoc()<CR>", { noremap = true, silent = true })

		-- Ruta completa del archivo actual
		local file = vim.fn.expand("%:p")
		-- Ruta de los distintas carpetas del proyecto
		local src_dir = root_dir .. "/src"
		local bin_dir = root_dir .. "/bin"
		local docs_dir = root_dir .. "/docs"
		-- Asegurar que solo la parte después de src/ se usa como class_path
		local relative_path = file:sub(#src_dir + 2) -- Remover src/ (y la barra extra)
		local class_path = relative_path:gsub("%.java$", "") -- Remover la extensión .java
		local package_path = relative_path:gsub("/[^/]+$", "") -- Obtener la ruta del paquete

		-- Función para ejecutar la clase Java actual
		function RunJavaClass()
			local compile_cmd = string.format(
				"cd %s && mkdir -p %s && javac -d %s $(find src -name '*.java')",
				root_dir,
				bin_dir,
				bin_dir
			)
			local run_cmd = string.format(
				"cd %s && java -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address='*':5005 -cp %s %s",
				root_dir,
				bin_dir,
				class_path
			)

			-- Abrir una terminal en Neovim y ejecutar los comandos
			vim.cmd("botright split | resize 16 | term " .. compile_cmd .. " && " .. run_cmd)
		end

		-- Función para generar la documentación de un paquete con Javadoc
		function DocJavaClass()
			vim.fn.system(
				string.format("cd %s && javadoc -d %s -sourcepath %s %s", root_dir, docs_dir, src_dir, package_path)
			)
		end

		-- Función para abrir la documentación de Javadoc de la clase actual
		function OpenJavaDoc()
			vim.fn.system(string.format("setsid -f firefox '%s/%s.html'", docs_dir, class_path))
		end
	end,
}
