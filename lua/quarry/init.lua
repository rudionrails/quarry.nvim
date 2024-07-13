--- Notify utility
---@param msg string The message to print
---@param level? number One of: vim.log.levels.DEBUG [[INFO, WARN, ERROR]]
local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = "quarry" })
end

---@class quarry.Config.mod: quarry.Config
local M = {}

---@class quarry.Server
local _server = {
	---@type string[]
	ensure_installed = {},
	---@type table<any, any>
	opts = {},
	---@type fun(name: string, opts: table<any, any>)
	setup = function(name, opts) end,
}

---@class quarry.Config
local _defaults = {
	---@type lsp.ClientCapabilities|(fun():lsp.ClientCapabilities)
	capabilities = function()
		return vim.tbl_deep_extend("force", {}, vim.lsp.protocol.make_client_capabilities())
	end,
	---@type string[]
	ensure_installed = {},
	---@type table<string, quarry.Server>
	servers = {},
}

---@private
M._is_setup = false

---@private
M._tools_installed = {}

--- Extract the ensure_installed from global and LSP server specific sections
--
---@param opts quarry.Config
---@param name? string
---@return string[] List of tools to be installed
function M._ensure_installed(opts, name)
	local list = vim.tbl_deep_extend("force", {}, opts.ensure_installed or {})

	if type(name) == "string" and opts.servers[name] then
		vim.list_extend(list, { name })
		vim.list_extend(list, opts.servers[name].ensure_installed or {})
	else
		for key, server in pairs(opts.servers) do
			vim.list_extend(list, { key })
			vim.list_extend(list, server.ensure_installed or {})
		end
	end

	return vim.fn.uniq(vim.fn.sort(list))
end

--- Setup the plugin
---@param opts quarry.Config
function M.setup(opts)
	if M._is_setup then
		notify("setup() already called")
		return -- do nothing
	else
		M._is_setup = true
	end

	local options = vim.tbl_deep_extend("force", {}, _defaults, opts or {})
	local capabilities = options.capabilities or {}
	if type(capabilities) == "function" then
		capabilities = capabilities() or {}
	end

	-- ensure lspconfig is available
	local has_lspconfig, lspconfig = pcall(require, "lspconfig")
	if not has_lspconfig then
		notify('Missing dependency required for setup: "lspconfig"', vim.log.levels.ERROR)
		return
	end

	-- setup servers from `servers` option
	local has_mason_lspconfig, mason_lspconfig = pcall(require, "mason-lspconfig")
	if has_mason_lspconfig then
		mason_lspconfig.setup({
			handlers = {
				function(name)
					local server = options.servers[name] or {}
					local server_opts =
						vim.tbl_deep_extend("force", { capabilities = vim.deepcopy(capabilities) }, server.opts or {})

					if type(server.setup) == "function" then
						server.setup(name, server_opts)
					else
						lspconfig[name].setup(server_opts)
					end
				end,
			},
		})
	end

	-- install tools from `ensure_installed` option
	local has_mason_registry, mason_registry = pcall(require, "mason-registry")
	if has_mason_registry then
		local function install(tool)
			local name = mason_lspconfig.get_mappings().lspconfig_to_mason[tool] or tool
			local p = mason_registry.get_package(name)

			if not p:is_installed() then
				M._tools_installed[tool] = true

				-- notify(
				-- 	string.format('Installing "%s"', p.name),
				-- 	vim.log.levels.INFO,
				-- )

				p:install()
			end
		end

		mason_registry:on("package:install:failed", function(p)
			if not M._tools_installed[p.name] then
				return
			end

			M._tools_installed[p.name] = false
			notify(
				string.format('"%s" could not installed. Check :MasonLog for details.', p.name),
				vim.log.levels.ERROR
			)
		end)

		mason_registry:on("package:install:success", function(p)
			if not M._tools_installed[p.name] then
				return
			end

			M._tools_installed[p.name] = false
			notify(string.format('"%s" was successfully installed', p.name))

			-- trigger FileType event to possibly load this newly installed LSP server
			vim.defer_fn(function()
				require("lazy.core.handler.event").trigger({
					event = "FileType",
					buf = vim.api.nvim_get_current_buf(),
				})
			end, 100)
		end)

		mason_registry.refresh(function()
			local ensure_installed = M._ensure_installed(options)

			for _, tool in ipairs(ensure_installed) do
				install(tool)
			end
		end)
	end
end

return M
