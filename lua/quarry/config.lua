local mason_lspconfig = require("mason-lspconfig")
local mason_registry = require("mason-registry")

local installer = require("quarry.installer")
local u = require("quarry.utils")

local M = {}

---@private
M._is_setup = false

---@class quarry.Server
M._server = {
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

---@lass quarry.Config
M._config = {
	---
	-- Enable LSP features
	features = {},

	---
	-- pass keymaps for
	keys = {},

	---
	-- Global capabilities that are passed to every LSP
	---@type lsp.ClientCapabilities|fun():lsp.ClientCapabilities
	capabilities = function()
		return vim.tbl_deep_extend("force", {}, vim.lsp.protocol.make_client_capabilities())
	end,

	---
	-- Global on_attach that is passed to every LSP
	---@type fun(client: vim.lsp.Client, bufnr: integer)
	on_attach = function(client, bufnr) end,

	---
	-- List of global tools to install
	---@type string[]
	ensure_installed = {},

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
	if M._is_setup then
		u.notify("setup() already called", vim.log.levels.WARN)
		return
	else
		M._is_setup = true
	end

	local _opts = vim.tbl_deep_extend("force", {}, M._config, opts or {})
	local _capabilities = type(_opts.capabilities) == "function" and _opts.capabilities() or _opts.capabilities
	local _on_attach = function(client, bufnr)
		if type(_opts.features) == "string" or type(_opts.features) == "table" and #_opts.features ~= 0 then
			require("quarry.features").setup(client, bufnr, _opts.features)
		end

		if type(_opts.keys) == "table" and #_opts.keys ~= 0 then
			require("quarry.keymaps").setup(client, bufnr, _opts.keys)
		end

		if type(_opts.on_attach) == "function" then
			_opts.on_attach(client, bufnr)
		end
	end

	-- setup servers from `servers` option
	mason_lspconfig.setup({
		handlers = {
			function(name)
				local setup = _opts.setup[name] or _opts.setup["_"]
				local server = vim.tbl_deep_extend("force", {}, M._server, _opts.servers[name] or {})
				local server_options = vim.tbl_deep_extend("force", {
					capabilities = vim.deepcopy(_capabilities),
					on_attach = _on_attach,
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
	installer.run(_opts.ensure_installed)

	for lsp, server in pairs(_opts.servers) do
		server = vim.tbl_deep_extend("force", {}, M._server, server or {})
		table.insert(server.ensure_installed, lsp)

		installer.run(server.ensure_installed, server.filetypes)
	end
end

return M
