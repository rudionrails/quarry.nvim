local M = {}

M._allowed_options = { "desc", "noremap", "remap", "expr", "nowait", "silent" }

---
-- Pretty much the same signature as [Lazy](https://lazy.folke.io/) key mappings
--
---@class quarry.Keymap
---@field [1] string Left-hand-side {lhs} of the mapping
---@field [2] string|fun(client, bufnr) Right-hand-side {rhs} of the mapping
---@field mode? string|string[] Mode short name (default "n")
---@field desc? string Human-readable description
---@field noremap? boolean
---@field remap? boolean
---@field expr? boolean
---@field nowait? boolean
---@field silent? boolean

---
-- Setup LSP client features for the provided buffer
--
---@param client vim.lsp.Client
---@param bufnr number
---@param keymaps quarry.Keymap[]
function M.setup(client, bufnr, keymaps)
	local _apply = function(keymap)
		local mode = keymap.mode or "n"
		local lhs = keymap[1]
		local rhs = keymap[2]
		local opts = { buffer = bufnr }

		for _, k in ipairs(M._allowed_options) do
			if keymap[k] ~= nil then
				opts[k] = keymap[k]
			end
		end

		vim.keymap.set(mode, lhs, rhs, opts)
	end

	for _, keymap in ipairs(keymaps) do
		_apply(keymap)
	end
end

return M
