# `quarry.nvim`

**quarry.nvim** is a plugin simplies the setup of [mason](https://github.com/williamboman/mason.nvim), [mason-lspconfig](https://github.com/williamboman/mason-lspconfig.nvim) and [lspconfig](https://github.com/neovim/nvim-lspconfig) for your **Neovim** configuration by orchestrating lsp setup and tools (formatter, linter) installation.

## ✨ Features

- Passes `vim.lsp.protocol.make_client_capabilities()` as default capabilities to any LSP
- Configure `ensure_installed` to install all available tools in mason, via mason-lspconfig

## ⚡️Requirements

- [`Neovim`](https://neovim.io/) >= 0.10.0
- [`mason`](https://github.com/williamboman/mason.nvim)
- [`mason-lspconfig`](https://github.com/williamboman/mason-lspconfig.nvim)
- [`lspconfig`](https://github.com/neovim/nvim-lspconfig)

## 📦 Installation

> [!NOTE]  
> By default, this plugin only sets up the standard lsp capabilities for generic LSP. You need to read the Configuration section for more sophisticated setup.

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
    {
        "rudionrails/quarry.nvim",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "neovim/nvim-lspconfig"
        },

    }
}

```

## ⚙️ Configuration

```lua
require("quarry").setup({
    -- define globally required mason tools
    ensure_installed ={ "lua_ls", "stylua", "luacheck" },
})
```
