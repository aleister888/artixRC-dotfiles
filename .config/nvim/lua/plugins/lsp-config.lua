local servers = {
	"lua_ls",
	"jdtls",
	"texlab",
	"bashls",
	"clangd",
	"markdown_oxide",
	"cssls",
}

return {
	{
		"williamboman/mason.nvim",
		opts = {},
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "rcarriga/nvim-notify" },
		opts = function()
			vim.keymap.set("n", "<leader>A", vim.lsp.buf.code_action, {})
			-- Mostrar diagnóstico en una ventana flotante
			vim.api.nvim_set_keymap(
				"n",
				"<leader>d1",
				":lua vim.diagnostic.open_float()<CR>",
				{ noremap = true, silent = true }
			)
			-- Mostrar diagnósticos en forma de lista
			vim.api.nvim_set_keymap(
				"n",
				"<leader>d2",
				":lua vim.diagnostic.setqflist()<CR>",
				{ noremap = true, silent = true }
			)
			-- Ir al siguiente diagnóstico
			vim.api.nvim_set_keymap(
				"n",
				"<leader>dn",
				":lua vim.diagnostic.goto_next()<CR>",
				{ noremap = true, silent = true }
			)
			-- Ir al diagnóstico anterior
			vim.api.nvim_set_keymap(
				"n",
				"<leader>dp",
				":lua vim.diagnostic.goto_prev()<CR>",
				{ noremap = true, silent = true }
			)

			local diagnostics_active = true
			function ToggleDiagnostics()
				diagnostics_active = not diagnostics_active
				if diagnostics_active then
					vim.diagnostic.enable()
					vim.notify("Análisis activado")
				else
					vim.diagnostic.disable()
					vim.notify("Análisis desactivado")
				end
			end

			vim.api.nvim_set_keymap(
				"n",
				"<leader>dt",
				":lua ToggleDiagnostics()<CR>",
				{ noremap = true, silent = true }
			)

			return {
				ensure_installed = servers,
			}
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		config = function()
			local lspconfig = require("lspconfig")
			local capabilities = vim.lsp.protocol.make_client_capabilities()

			-- LSP servers to configure
			for _, lsp in ipairs(servers) do
				lspconfig[lsp].setup({
					capabilities = capabilities,
				})
			end
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
