local M = {}

---
-- Notify utility
--
---@param msg string The message to print
---@param level? number One of: vim.log.levels.DEBUG [[INFO, WARN, ERROR]]
function M.notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = "quarry" })
end

return M
