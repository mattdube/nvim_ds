local config = require('minuet').config
local common = require 'minuet.backends.common'

local M = {}

M.is_available = function()
    if vim.env.OPENAI_API_KEY == nil or vim.env.OPENAI_API_KEY == '' then
        return false
    else
        return true
    end
end

if not M.is_available() then
    vim.notify('OpenAI API key is not set', vim.log.levels.ERROR)
end

M.complete = function(context_before_cursor, context_after_cursor, callback)
    local options = vim.deepcopy(config.provider_options.openai)
    options.name = 'OpenAI'
    options.end_point = 'https://api.openai.com/v1/chat/completions'
    options.api_key = 'OPENAI_API_KEY'

    common.complete_openai_base(options, context_before_cursor, context_after_cursor, callback)
end

return M
