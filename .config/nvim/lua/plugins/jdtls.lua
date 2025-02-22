return {
	"mfussenegger/nvim-jdtls",
	lazy = true,
	ft = "java",
	config = function()
		local home = vim.env.HOME

		local jdtls = require("jdtls")

		-- Para pruebas unitarias
		local bundles = {
			vim.fn.glob(
				home .. "/.local/share/nvim/mason/share/java-debug-adapter/com.microsoft.java.debug.plugin.jar"
			),
		}
		vim.list_extend(
			bundles,
			vim.split(vim.fn.glob(home .. "/.local/share/nvim/mason/share/java-test/*.jar", 1), "\n")
		)
		-- Mapeo para ejecutar la clase actual con <leader>g
		vim.keymap.set("n", "<leader>g", ":lua RunJavaClass()<CR>", { noremap = true, silent = true })
		vim.keymap.set("n", "<leader>G", ":botright terminal java %<CR>:startinsert<CR>", { silent = true })

		vim.keymap.set("n", "<leader>jd", ":lua DocJavaClass()<CR>", { noremap = true, silent = true })
		vim.keymap.set("n", "<leader>jD", ":lua OpenJavaDoc()<CR>", { noremap = true, silent = true })

		-- Directorio del proyecto
		local root_dir = vim.fs.dirname(vim.fs.find({
			".git",
			"pom.xml",
			"build.gradle",
			".project",
		}, { upward = true })[1])
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
			local run_cmd = string.format("cd %s && java -cp %s %s", root_dir, bin_dir, class_path)

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

		-- See `:help vim.lsp.start_client` for an overview of the supported `config` options.
		local config = {
			root_dir = root_dir,
			cmd = { vim.fn.expand("~/.local/share/nvim/mason/bin/jdtls") },
			settings = {
				java = {
					home = "/usr/lib/jvm/default-runtime",
					eclipse = {
						downloadSources = true,
					},
					configuration = {
						updateBuildConfiguration = "interactive",
					},
					maven = {
						downloadSources = true,
					},
					implementationsCodeLens = {
						enabled = true,
					},
					referencesCodeLens = {
						enabled = true,
					},
					references = {
						includeDecompiledSources = true,
					},
					signatureHelp = { enabled = true },
					completion = {
						favoriteStaticMembers = {
							"org.hamcrest.MatcherAssert.assertThat",
							"org.hamcrest.Matchers.*",
							"org.hamcrest.CoreMatchers.*",
							"org.junit.jupiter.api.Assertions.*",
							"java.util.Objects.requireNonNull",
							"java.util.Objects.requireNonNullElse",
							"org.mockito.Mockito.*",
						},
						importOrder = {
							"java",
							"javax",
							"com",
							"org",
						},
					},
					sources = {
						organizeImports = {
							starThreshold = 9999,
							staticStarThreshold = 9999,
						},
					},
					codeGeneration = {
						toString = {
							template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
						},
						useBlocks = true,
					},
				},
			},
			capabilities = require("cmp_nvim_lsp").default_capabilities(),
			flags = {
				allow_incremental_sync = true,
			},
			init_options = {
				bundles = bundles,
				extendedClientCapabilities = jdtls.extendedClientCapabilities,
			},
		}

		-- Debugging
		config["on_attach"] = function()
			jdtls.setup_dap({ hotcodereplace = "auto" })
			require("jdtls.dap").setup_dap_main_class_configs()
		end

		jdtls.start_or_attach(config)
	end,
}
