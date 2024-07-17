local mason_lspconfig = require("mason-lspconfig")
local mason_registry = require("mason-registry")

local u = require("quarry.utils")

local M = {}

---@class quarry.installer.Options
M._opts = {
	---@type string
	name = "",
	---@type string[]
	filetypes = {},
}

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
		local p = mason_registry.get_package(name)

		if not p:is_installed() then
			M._tools_installed[p.name] = true

			-- notify(
			-- 	string.format('Installing "%s"', p.name),
			-- 	vim.log.levels.INFO,
			-- )

			p:install()
		end
	end
end

---@param tools string[]
---@params opts? quarry.installer.Options
function M.run(tools, opts)
	if #tools == 0 then
		return
	end

	opts = vim.tbl_deep_extend("force", {}, M._opts, opts or {})

	if #opts.filetypes == 0 then
		-- install now
		M._run(tools)
	else
		-- register FileType event and install later
		local group = vim.api.nvim_create_augroup(
			string.format("quarry_%s_%s", table.concat(tools, "_"), table.concat(opts.filetypes, "_")),
			{ clear = true }
		)
		-- local group = vim.api.nvim_create_augroup("quarry_" .. lsp .. "_" .. table.concat(tools, "_"))
		local callback = function()
			vim.api.nvim_del_augroup_by_id(group)
			M._run(tools)
		end

		vim.api.nvim_create_autocmd("FileType", { group = group, pattern = opts.filetypes, callback = callback })
	end
end

return M
