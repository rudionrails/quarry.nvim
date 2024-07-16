-- @module quarry
local M = {}

---
-- @param opts? quarry.Config
function M.setup(opts)
	require("quarry.config").setup(opts)
end

return M
