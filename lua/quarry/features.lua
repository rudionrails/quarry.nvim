local u = require("quarry.utils")

local M = {}

---
-- Features are what the LSP client is able to support via `client.supports_method()`
--
-- Enable all features (default)
--   quarry.setup({ features = true })
--
-- Disable all features
--   quarry.setup({ features = false })
--
-- Enable selected features with their default configuration
--   quarry.setup({
--     features = {
--       "textDocument/documentHighlight", -- uses the default function from quarry.nvim
--       ["textDocument/inlayHint"] = {
--         cond = "textDocument/inlayHint" -- this is used as default and taken from key
--         setup = function(client, bufnr) -- only executes when `cond` is satisied
--
--         end,
--       },
--       ["textDocument/codeLens"] = function(client, bufnr) -- no magic applied, all logic is with you
--
--       end,
--     }
--   })
--
-- @type table<string, quarry.Feature>|string|boolean
M._features = {
	-- Highlight on current word
	["textDocument/documentHighlight"] = function(client, bufnr)
		if not client.supports_method("textDocument/documentHighlight") then
			return
		end

		local group = vim.api.nvim_create_augroup("quarry_textDocument/documentHighlight", { clear = false })

		vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
			group = group,
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.document_highlight()
			end,
		})

		-- Remove highlight on current word
		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
			group = group,
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.clear_references()
			end,
		})

		return function()
			vim.lsp.buf.clear_references()
			vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
		end
	end,

	-- enable inlay hints
	["textDocument/inlayHint"] = function(client, bufnr)
		if not client.supports_method("textDocument/inlayHint") then
			return
		end

		vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
	end,

	-- enable code lens
	["textDocument/codeLens"] = function(client, bufnr)
		if not client.supports_method("textDocument/codeLens") then
			return
		end

		local group = vim.api.nvim_create_augroup("quarry_textDocument/codeLens", { clear = false })

		vim.lsp.codelens.refresh()
		vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
			group = group,
			buffer = bufnr,
			callback = function()
				vim.lsp.codelens.refresh()
			end,
		})

		return function()
			vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
		end
	end,
}

---
-- Setup LSP client features for the provided buffer
--
---@param client vim.lsp.Client
---@param bufnr number
---@param features table<string, fun()>
function M.setup(client, bufnr, features)
	local _teardowns = {}
	local _apply = function(fn)
		local teardown = fn(client, bufnr)

		if type(teardown) == "function" then
			table.insert(_teardowns, teardown)
		end
	end

	for feature, setup in pairs(features) do
		if type(feature) == "string" then
			_apply(setup)
		elseif type(setup) == "string" and M._features[setup] then
			_apply(M._features[setup])
		else
			u.notify(string.format('"%s" is not a valid type for features', setup), vim.log.levels.ERROR)
		end
	end

	if #_teardowns ~= 0 then
		vim.api.nvim_create_autocmd("LspDetach", {
			buffer = bufnr,
			callback = function(event)
				if event.data.client_id ~= client.id or event.buf ~= bufnr then
					return
				end

				for _, teardown in ipairs(_teardowns) do
					teardown(client, bufnr)
				end
			end,
		})
	end
end

return M
