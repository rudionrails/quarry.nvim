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
---@param keys quarry.Keymap[]
function M.setup(client, bufnr, keys)
	-- Applies keymap to current buffer
	local _map = function(key)
		local mode = key.mode or "n"
		local lhs = key[1]
		local rhs = key[2]
		local opts = { buffer = bufnr }

		if type(key[2]) == "function" then
			rhs = function()
				key[2](client, bufnr)
			end
		end

		for _, k in ipairs(M._allowed_options) do
			if key[k] ~= nil then
				opts[k] = key[k]
			end
		end

		vim.keymap.set(mode, lhs, rhs, opts)
	end

	for _, key in ipairs(keys) do
		_map(key)
	end
end

return M
