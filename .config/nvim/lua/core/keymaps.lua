vim.g.mapleader = ","

local keymap = keymap

vim.keymap.set("n", "<leader>wq", ":wq<CR>")
vim.keymap.set("n", "<leader>qq", ":q!<CR>")
vim.keymap.set("n", "<leader>ww", ":w<CR>")

vim.keymap.set("n", "<leader>v", "<C-w>v")
vim.keymap.set("n", "<leader>V", "<C-w>s")

-- Desplazarse por el texto
vim.keymap.set("n", "<ScrollWheelUp>", "k<C-G>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-ScrollWheelUp>", "5k<C-G>", { noremap = true, silent = true })

vim.keymap.set("n", "<ScrollWheelDown>", "j<C-G>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-ScrollWheelDown>", "5j<C-G>", { noremap = true, silent = true })

vim.keymap.set("n", "<C-Up>", "5k<C-G>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-Down>", "5j<C-G>", { noremap = true, silent = true })

vim.keymap.set("n", "=", "$<C-G>", { noremap = true, silent = true })
vim.keymap.set("v", "=", "$h", { noremap = true, silent = true })
vim.keymap.set("n", "G", ":$<CR><C-G>", { noremap = true, silent = true })
vim.keymap.set("n", "gg", ":1<CR><C-G>", { noremap = true, silent = true })

-- Alternar corrección ortográfica en español con F4
vim.keymap.set("n", "<F4>", ":setlocal spell! spelllang=es_es<CR>", { silent = true })
vim.keymap.set("i", "<F4>", "<C-O>:setlocal spell! spelllang=es_es<CR>", { silent = true })

-- Alternar corrección ortográfica en inglés con F5
vim.keymap.set("n", "<F5>", ":setlocal spell! spelllang=en_us<CR>", { silent = true })
vim.keymap.set("i", "<F5>", "<C-O>:setlocal spell! spelllang=en_us<CR>", { silent = true })

-- Encapsular texto seleccionado
vim.keymap.set("v", '"', 's"<C-r>""', { noremap = true, silent = true })
vim.keymap.set("v", "'", "s'<C-r>\"'", { noremap = true, silent = true })
vim.keymap.set("v", "`", 's`<C-r>"`', { noremap = true, silent = true })
vim.keymap.set("v", "2`", 's``<C-r>"``', { noremap = true, silent = true })
vim.keymap.set("v", "$", 's$<C-r>"$', { noremap = true, silent = true })
vim.keymap.set("v", "_", 's_<C-r>"_', { noremap = true, silent = true })
vim.keymap.set("v", "<leader>_", 's__<C-r>"__', { noremap = true, silent = true })
vim.keymap.set("v", "(", 's(<C-r>")', { noremap = true, silent = true })
vim.keymap.set("v", ")", 's(<C-r>")', { noremap = true, silent = true })
vim.keymap.set("v", "{", 's{<C-r>"}', { noremap = true, silent = true })
vim.keymap.set("v", "}", 's{<C-r>"}', { noremap = true, silent = true })
vim.keymap.set("v", "[", 's[<C-r>"]', { noremap = true, silent = true })
vim.keymap.set("v", "]", 's[<C-r>"]', { noremap = true, silent = true })
vim.keymap.set("v", "¿", 's¿<C-r>"?', { noremap = true, silent = true })
vim.keymap.set("v", "?", 's¿<C-r>"?', { noremap = true, silent = true })

-- Modo insert al final de la línea
vim.keymap.set("n", "<C-i>", "A", { noremap = true, silent = true })

-- Spawnear scratchpad
vim.keymap.set("n", "<leader>s", function()
	local terminal = os.getenv("TERMINAL") or ""
	local termtitle = os.getenv("TERMTITLE") or ""
	local cmd = string.format('setsid -f sh -c "%s %s scratchpad"', terminal, termtitle)
	vim.fn.execute("!" .. cmd)
end, { silent = true })

-- Mapeos para Java
-- Autocomando para el tipo de archivo Java
vim.api.nvim_create_autocmd("FileType", {
	pattern = "java",
	callback = function()
		-- Mapeo para ejecutar el comando en un terminal
		vim.keymap.set("n", "<leader>g", ":botright terminal java %<CR>:startinsert<CR>", { silent = true })
	end,
})
