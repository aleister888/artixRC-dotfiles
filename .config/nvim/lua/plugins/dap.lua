return {
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		opts = function()
			return {
				ensure_installed = {
					"java-debug-adapter",
					"java-test",
				},
			}
		end,
	},
	{
		"rcarriga/nvim-dap-ui",
		event = "VeryLazy",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-neotest/nvim-nio",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			dapui.setup()

			-- Auto open/close UI when debugging starts/stops
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end

			-- Function to manually toggle the UI
			vim.api.nvim_set_keymap(
				"n",
				"<leader>du",
				":lua require'dapui'.toggle()<CR>",
				{ noremap = true, silent = true }
			)

			dap.adapters.java = function(callback)
				callback({
					type = "server",
					host = "localhost",
					port = 5005,
				})
			end

			dap.configurations.java = {
				{
					request = "launch",
					type = "java",
					port = 5005,
				},
			}
		end,
	},
}
