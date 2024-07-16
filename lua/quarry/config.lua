local lspconfig = require("lspconfig")
local mason_lspconfig = require("mason-lspconfig")
local mason_registry = require("mason-registry")

local installer = require("quarry.installer")
local notify = require("quarry.utils").notify

---@class quarry.Server
---@field ensure_installed string[] The list of tools to install for the server
---@field ft? string[] Specify the filetypes when to install the tools
---@field opts? table<any, any> The LSP-specific options
---@field setup? fun(name: string, opts: table<any any>) Custom setup function for the LSP (if not defined, generic default will be used)

---@class quarry.Config
---@field capabilities? lsp.ClientCapabilities|fun():lsp.ClientCapabilities Will be passed to every LSP
---@field ensure_installed? string[] The list of tools to be installed
---@field servers? table<string, quarry.Server> Configure every LSP individually if needed

local M = {}

---@private
M._is_setup = false

---@type quarry.Config
---@private
M._config = {
	capabilities = function()
		return vim.tbl_deep_extend("force", {}, vim.lsp.protocol.make_client_capabilities())
	end,
	ensure_installed = {},
	servers = {},
}

---@type quarry.Server
---@private
M._server = {
	ensure_installed = {},
	opts = {},
}

--- Setup the plugin
---@param opts? quarry.Config
function M.setup(opts)
	if M._is_setup then
		notify("setup() already called", vim.log.levels.WARN)
		return
	else
		M._is_setup = true
	end

	local options = vim.tbl_deep_extend("force", {}, M._config, opts or {})
	local capabilities = type(options.capabilities) == "function" and options.capabilities() or options.capabilities

	-- setup servers from `servers` option
	mason_lspconfig.setup({
		handlers = {
			function(name)
				local server = vim.tbl_deep_extend("force", {}, M._server, options.servers[name] or {})
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

	-- install tools from `ensure_installed` option
	mason_registry:on("package:install:success", installer.on_success)
	mason_registry:on("package:install:failed", installer.on_failed)

	installer.run(options.ensure_installed)

	for lsp, server in pairs(options.servers) do
		server = vim.tbl_deep_extend("force", M._server, server or {})
		installer.run(server.ensure_installed, { name = lsp, ft = server.ft })
	end
end

return M