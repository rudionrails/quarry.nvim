local M = {}

---@class quarry.Server
M._server_defaults = {
	---
	-- Conditionally enable/disable server
	---@param ctx { filename: string }
	cond = function(ctx)
		return true
	end,

	---
	-- Specify the filetypes when to install the tools
	---@type string[]
	filetypes = {},

	---
	-- List of tools to install for the server
	---@type string[]
	tools = {},

	---
	-- The LSP-specific configuration
	---@type table<any, any>
	config = {},
}

---
-- Notify utility
--
---@param msg string The message to print
---@param level? number One of: vim.log.levels.DEBUG [[INFO, WARN, ERROR]]
function M.notify(msg, level)
	vim.notify(string.format("[quarry.nvim] %s", msg), level or vim.log.levels.INFO)
end

return M
