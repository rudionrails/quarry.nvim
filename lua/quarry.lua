-- @module quarry
local M = {}

---
-- The main setup function
--
---@param opts? quarry.Config
function M.setup(opts)
	require("quarry.config").setup(opts)
end

return M
