local ALLOWED_OPTIONS = { "desc", "noremap", "remap", "expr", "nowait", "silent" }

local M = {}

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

-- Setup LSP client features for the provided buffer
--
---@param client vim.lsp.Client
---@param bufnr number
---@param keymap table<string, quarry.Keymap>
function M.setup(_, bufnr, keymap)
	for lhs, config in pairs(keymap) do
		-- local lhs = key[1]
		-- local rhs = key[2]
		local rhs = config[1]
		local mode = config.mode or "n"
		local opts = { buffer = bufnr }

		for _, k in ipairs(ALLOWED_OPTIONS) do
			if config[k] ~= nil then
				opts[k] = config[k]
			end
		end

		vim.keymap.set(mode, lhs, rhs, opts)
	end
end

return M
