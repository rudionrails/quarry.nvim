local mason_lspconfig = require("mason-lspconfig")
local mason_registry = require("mason-registry")

local u = require("quarry.utils")

local M = {}

---@private
M._tools_installed = {}

---@param p: Package
function M.on_success(p)
	if not M._tools_installed[p.name] then
		return
	end

	M._tools_installed[p.name] = false

	-- trigger FileType event to possibly load the newly installed tools
	vim.defer_fn(function()
		vim.api.nvim_exec_autocmds("FileType", { buffer = vim.api.nvim_get_current_buf() })
	end, 100)
end

---@param p: Package
function M.on_failed(p)
	if not M._tools_installed[p.name] then
		return
	end

	M._tools_installed[p.name] = false
	u.notify(string.format('"%s" could not be installed. Check :MasonLog for details.', p.name), vim.log.levels.ERROR)
end

---@private
---@param tools string[]
function M._run(tools)
	for _, tool in ipairs(tools) do
		local name = mason_lspconfig.get_mappings().lspconfig_to_mason[tool] or tool
		local has_package, p = pcall(mason_registry.get_package, name)

		if not has_package then
			u.notify(string.format('"%s" not found in Mason registry.', name), vim.log.levels.WARN)
		end

		if has_package and not p:is_installed() then
			M._tools_installed[p.name] = true

			-- notify(
			-- 	string.format('Installing "%s"', p.name),
			-- 	vim.log.levels.INFO,
			-- )

			p:install()
		end
	end
end

---
-- Install the provided tools via mason, mason-lspconfig
--
---@param tools string[]
---@param filetypes? string[]
function M.run(tools, filetypes)
	if #tools == 0 then
		return
	end

	if #filetypes == 0 then
		-- install now
		M._run(tools)
	else
		-- register FileType event and install later
		local group = vim.api.nvim_create_augroup(
			string.format("quarry_%s_%s", table.concat(tools, "_"), table.concat(filetypes, "_")),
			{ clear = true }
		)

		vim.api.nvim_create_autocmd("FileType", {
			group = group,
			pattern = filetypes,
			callback = function()
				vim.api.nvim_del_augroup_by_id(group)
				M._run(tools)
			end,
		})
	end
end

return M
