-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.cmd [[packadd! nvim-lspconfig]]
vim.cmd [[packadd! lspsaga.nvim]]
vim.cmd [[packadd! aerial.nvim]]
vim.cmd [[packadd! lsp_signature.nvim]]
vim.cmd [[packadd! lua-dev.nvim]]

local opts = function(options)
    return {
        noremap = true,
        silent = true,
        desc = options[1] or options.desc,
        callback = options[2] or options.callback,
    }
end

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    -- vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
    local bufmap = vim.api.nvim_buf_set_keymap

    -- Mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    -- vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    --  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    bufmap(bufnr, 'n', '<Leader>td', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts { 'lsp type definition' })
    --
    --  vim.api.nvim_set_keymap('n', '<space>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
    -- vim.api.nvim_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
    -- vim.api.nvim_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
    -- vim.api.nvim_set_keymap('n', '<space>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)
    --

    -- find definition and reference simultaneously
    -- vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', "<cmd>lua require'lspsaga.provider'.lsp_finder()<CR>", opts)
    -- open a separate window to show reference

    -- reference
    -- stylua: ignore
    bufmap( bufnr, 'n', 'gr', '', opts {
        desc = 'lsp references telescope',
        callback = function()
            require('telescope.builtin').lsp_references {
                layout_strategies = 'vertical',
                jump_type = 'tab',
            }
        end,
    }
    )

    -- code action
    -- bufmap(bufnr, 'n', '<Leader>ca', "<cmd>lua require('lspsaga.codeaction').code_action()<CR>", opts {})
    -- bufmap(bufnr, 'v', '<Leader>ca', ":lua require('lspsaga.codeaction').range_code_action()<CR>", opts {})
    bufmap(bufnr, 'n', '<Leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts { 'lsp code action' })
    bufmap(bufnr, 'x', '<Leader>ca', ':<C-U>lua vim.lsp.buf.range_code_action()<CR>', opts { 'lsp range code action' })

    -- hover
    bufmap(bufnr, 'n', 'gh', '<cmd>Lspsaga hover_doc<CR>', opts { 'lspsaga hover doc' })
    -- stylua: ignore
    bufmap( bufnr, 'n', '<C-f>', '', opts {
        desc = 'lspsaga smartscroll downward',
        callback = function()
            require('lspsaga.action').smart_scroll_with_saga(1, '<C-f>')
        end,
    }
    )
    -- stylua: ignore
    bufmap( bufnr, 'n', '<C-b>', '', opts {
        desc = 'lspsaga smartscroll upward',
        callback = function()
            require('lspsaga.action').smart_scroll_with_saga(-1, '<C-b>')
        end,
    }
    )

    -- use glow-hover
    bufmap(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts { 'lsp hover by glow' })

    -- signaturehelp
    -- stylua: ignore
    bufmap(bufnr, 'n', '<Leader>sh', '',
        opts { 'lspsaga signature help', require('lspsaga.signaturehelp').signature_help }
    )
    -- "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)

    -- rename
    bufmap(bufnr, 'n', '<Leader>rn', '<cmd>Lspsaga rename<CR>', opts { 'lspsaga rename' })

    -- go to definition, implementation
    -- stylua: ignore
    bufmap(bufnr, 'n', 'gd', '', opts {
        desc = 'lsp go to definition',
        callback = function()
            require('telescope.builtin').lsp_definitions {
                layout_strategies = 'vertical',
                jump_type = 'tab',
            }
        end,
    }
    )
    -- stylua: ignore
    bufmap(bufnr, 'n', '<Leader>gi', '', opts {
        desc = 'lsp go to implementation',
        callback = function()
            require('telescope.builtin').lsp_implementations {
                layout_strategies = 'vertical',
                jump_type = 'tab',
            }
        end,
    })
    -- keymap(bufnr, 'n', 'gd', "<cmd>lua require'lspsaga.provider'.preview_definition()<CR>", opts)

    -- workspace
    local bufcmd = vim.api.nvim_buf_create_user_command

    bufcmd(bufnr, 'LspWorkspace', function(options)
        if options.args == 'add' then
            vim.lsp.buf.add_workspace_folder()
        elseif options.args == 'remove' then
            vim.lsp.buf.remove_workspace_folder()
        elseif options.args == 'show' then
            vim.pretty_print(vim.lsp.buf.list_workspace_folders())
        end
    end, {
        nargs = 1,
        complete = function(_, _, _)
            return { 'add', 'remove', 'show' }
        end,
    })

    -- format
    bufmap(bufnr, 'n', '<Leader>fm', '', opts { 'lsp format', vim.lsp.buf.formatting })
    bufmap(bufnr, 'v', '<Leader>fm', ':<C-U>lua vim.lsp.buf.range_formatting()<CR>', opts { 'lsp range format' })

    -- diagnostic
    -- stylua: ignore
    bufmap(bufnr, 'n', '<Leader>ds', '', opts { 'lsp diagnostics by telescope', require('telescope.builtin').diagnostics })
    bufmap(bufnr, 'n', '[d', '<cmd>Lspsaga diagnostic_jump_prev<CR>', opts { 'lspsaga prev diagnostic' })
    bufmap(bufnr, 'n', ']d', '<cmd>Lspsaga diagnostic_jump_next<CR>', opts { 'lspsaga next diagnostic' })
    -- diagnostic show in line or in cursor
    -- stylua: ignore
    bufmap( bufnr, 'n', '<Leader>dl', '<cmd>Lspsaga show_line_diagnostics<CR>', opts { 'lspsaga current line diagnostic' })
    -- vim.api.nvim_buf_set_keymap(bufnr, 'n',
    --     '<Leader>dc', "<cmd>lua require'lspsaga.diagnostic'.show_cursor_diagnostics()<CR>", opts)

    require('aerial').on_attach(client, bufnr)
    require('conf.lsp_tools').signature(bufnr)
end

-- Setup lspconfig.
local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
-- --
-- -- -- copied from https://github.com/ray-x/lsp_signature.nvim/blob/master/tests/init_paq.lua
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = { 'documentation', 'detail', 'additionalTextEdits' },
}

-- Copied from lspconfig/server_configurations/pylsp.lua
local function python_root_dir(fname)
    local util = require 'lspconfig.util'
    local root_files = {
        'pyproject.toml',
        'setup.py',
        'setup.cfg',
        'requirements.txt',
        'Pipfile',
    }
    return util.root_pattern(unpack(root_files))(fname) or util.find_git_ancestor(fname)
end

require('lspconfig').pyright.setup {
    on_attach = on_attach,
    capabilities = capabilities,
    root_dir = python_root_dir,
    settings = {
        python = {
            pythonPath = require('bin_path').python,
        },
    },
    flags = {
        debounce_text_changes = 150,
    },
}

require('lspconfig').r_language_server.setup {
    on_attach = on_attach,
    flags = {
        debounce_text_changes = 150,
    },
    capabilities = capabilities,
}
require('lspconfig').texlab.setup {
    on_attach = on_attach,
    flags = { debounce_text_changes = 150 },
    capabilities = capabilities,
}

require('lspconfig').julials.setup {
    on_attach = on_attach,
    flags = {
        debounce_text_changes = 150,
    },
    capabilities = capabilities,
}

require('lspconfig').clangd.setup {
    on_attach = on_attach,
    capabilities = capabilities,
}

local lua_runtime_path = {}
table.insert(lua_runtime_path, 'lua/?.lua')
table.insert(lua_runtime_path, 'lua/?/init.lua')

require('lua-dev').setup {}

require('lspconfig').sumneko_lua.setup {
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
        Lua = {
            runtime = {
                version = 'LuaJIT',
                path = lua_runtime_path,
            },
            diagnostics = {
                globals = { 'vim' },
            },
            workspace = {
                library = vim.api.nvim_get_runtime_file('', true),
            },
            telemetry = {
                enable = false,
            },
        },
    },
}

require('lspconfig').vimls.setup {
    on_attach = on_attach,
    capabilities = capabilities,
}

require('lspconfig').sqls.setup {
    cmd = { require('bin_path').sqls },
    on_attach = function(client, bufnr)
        vim.cmd [[packadd! sqls.nvim]]

        on_attach(client, bufnr)
        require('sqls').on_attach(client, bufnr)
        local bufmap = vim.api.nvim_buf_set_keymap
        bufmap(bufnr, 'n', '<LocalLeader>ss', '<cmd>SqlsExecuteQuery<CR>', { silent = true })
        bufmap(bufnr, 'v', '<LocalLeader>ss', '<cmd>SqlsExecuteQuery<CR>', { silent = true })
        bufmap(bufnr, 'n', '<LocalLeader>sv', '<cmd>SqlsExecuteQueryVertical<CR>', { silent = true })
        bufmap(bufnr, 'v', '<LocalLeader>sv', '<cmd>SqlsExecuteQueryVertical<CR>', { silent = true })
    end,
    capabilities = capabilities,
    single_file_support = false,
    on_new_config = function(new_config, new_rootdir)
        new_config.cmd = {
            require('bin_path').sqls,
            '-config',
            new_rootdir .. '/config.yml',
        }
    end,
}

vim.fn.sign_define('DiagnosticSignError', { text = '✗', texthl = 'DiagnosticSignError' })
vim.fn.sign_define('DiagnosticSignWarn', { text = '!', texthl = 'DiagnosticSignWarn' })
vim.fn.sign_define('DiagnosticSignInformation', { text = '', texthl = 'DiagnosticSignInfo' })
vim.fn.sign_define('DiagnosticSignHint', { text = '', texthl = 'DiagnosticSignHint' })
