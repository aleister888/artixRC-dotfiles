return {
	{
		"williamboman/mason.nvim",
		opts = {},
	},
	{
		"williamboman/mason-lspconfig.nvim",
		opts = function()
			return {
				ensure_installed = {
					"jdtls",
					"texlab",
					"bashls",
				},
			}
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"jose-elias-alvarez/null-ls.nvim",
		},
		config = function()
			local lspconfig = require("lspconfig")
			local null_ls = require("null-ls")
			local capabilities = vim.lsp.protocol.make_client_capabilities()

			-- LSP servers to configure
			local servers = { "jdtls", "texlab", "bashls" }
			for _, lsp in ipairs(servers) do
				lspconfig[lsp].setup({
					capabilities = capabilities,
				})
			end

			-- Configuración de null-ls para shellcheck
			null_ls.setup({
				sources = {
					null_ls.builtins.diagnostics.shellcheck,
				},
			})
		end,
	},
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp", -- Para LSP
			"quangnguyen30192/cmp-nvim-ultisnips", -- Para ultisnips
			"L3MON4D3/LuaSnip", -- Dependencia de snippets
			"hrsh7th/cmp-buffer", -- Autocompletado desde el buffer
			"hrsh7th/cmp-path", -- Autocompletado de rutas
			"hrsh7th/cmp-nvim-lua", -- Autocompletado para Lua
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			-- Setup de nvim-cmp
			cmp.setup({
				snippet = {
					expansion = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				sources = {
					{ name = "nvim_lsp" },
					{ name = "ultisnips" },
					{ name = "buffer" },
					{ name = "path" },
					{ name = "nvim_lua" },
				},
				mapping = {
					["<S-Tab>"] = cmp.mapping.confirm({ select = true }), -- Shift+Tab para confirmar selección
					["<Down>"] = cmp.mapping.select_next_item(), -- Flecha Abajo para ir a la siguiente opción
					["<Up>"] = cmp.mapping.select_prev_item(), -- Flecha Arriba para ir a la opción anterior
				},
				window = {
					completion = {
						-- Borde para el menú de autocompletado
						border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
					},
					documentation = {
						-- Borde para la documentación
						border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
					},
				},
				formatting = {
					format = function(entry, vim_item)
						vim_item.kind = string.format("%s %s", vim_item.kind, entry.source.name) -- Mostrar el nombre de la fuente
						return vim_item
					end,
				},
			})
		end,
	},
}
