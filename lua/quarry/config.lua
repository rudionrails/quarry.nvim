local mason_lspconfig = require("mason-lspconfig")
local mason_registry = require("mason-registry")

local installer = require("quarry.installer")
local u = require("quarry.utils")

local M = {}

local _is_setup = false

---@class quarry.Server
local _server = {
	---
	-- Specify the filetypes when to install the tools
	---@type string[]
	filetypes = {},

	---
	-- List of tools to install for the server
	---@type string[]
	ensure_installed = {},

	---
	-- The LSP-specific options
	---@type table<any, any>
	opts = {},
}

---@class quarry.Config
M.defaults = {
	---
	-- List of global tools to install
	---@type string[]
	ensure_installed = {},

	---
	-- Enable LSP features for attached client
	features = {},

	---
	-- Pass keymaps for attached client
	---@type table<string, quarry.Keymap>
	keys = {},

	---
	-- Global capabilities that are passed to every LSP
	---@type lsp.ClientCapabilities|fun():lsp.ClientCapabilities
	capabilities = vim.lsp.protocol.make_client_capabilities,

	---
	-- Global on_attach that is passed to every LSP
	---@type fun(client: vim.lsp.Client, bufnr: integer)
	on_attach = function(client, bufnr) end,

	---
	-- Configure every LSP individually. Ideal to separate into multiple files.
	---@type table<string, quarry.Server>
	servers = {},

	---
	-- Default setup function assumes lspconfig, but will gracefully do nothing if not available,
	-- so that you can override with your custom implementation.
	---@type table<string, fun(nane: string, opts: table<any, any>)>
	setup = {
		_ = function(name, opts)
			local ok, lspconfig = pcall(require, "lspconfig")
			if ok then
				lspconfig[name].setup(opts)
			end
		end,
	},
}

--- Setup the plugin
---@param opts? quarry.Config
function M.setup(opts)
	if _is_setup then
		u.notify("setup() already called", vim.log.levels.WARN)
		return
	else
		_is_setup = true
	end

	local config = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})

	local capabilities = type(config.capabilities) == "function" and config.capabilities() or config.capabilities
	local on_attach = function(client, bufnr)
		require("quarry.features").setup(client, bufnr, config.features)
		require("quarry.keymaps").setup(client, bufnr, config.keys)

		config.on_attach(client, bufnr)
	end

	-- setup servers from `servers` option
	mason_lspconfig.setup({
		handlers = {
			function(name)
				local setup = config.setup[name] or config.setup["_"]
				local server = vim.tbl_deep_extend("force", {}, _server, config.servers[name] or {})
				local server_options = vim.tbl_deep_extend("force", {
					capabilities = capabilities,
					on_attach = on_attach,
				}, server.opts or {})

				if type(setup) == "function" then
					setup(name, server_options)
				else
					local ok, lspconfig = pcall(require, "lspconfig")
					if ok then
						lspconfig[name].setup(server_options)
					else
						u.notify(string.format('No LSP setup() function defined for "%s"', name), vim.log.levels.WARN)
					end
				end
			end,
		},
	})

	-- install tools from `ensure_installed` option
	mason_registry:on("package:install:success", installer.on_success)
	mason_registry:on("package:install:failed", installer.on_failed)
	installer.run(config.ensure_installed)

	for lsp, server in pairs(config.servers) do
		server = vim.tbl_deep_extend("force", {}, _server, server or {})
		table.insert(server.ensure_installed, lsp)

		installer.run(server.ensure_installed, server.filetypes)
	end
end

return M
