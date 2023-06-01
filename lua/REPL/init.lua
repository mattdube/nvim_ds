local M = {}
local api = vim.api
local fn = vim.fn

M.formatter = {}

local default_config = function()
    return {
        buflisted = true,
        scratch = true,
        ft = 'REPL',
        wincmd = 'belowright 15 split',
        metas = {
            aichat = { cmd = 'aichat', formatter = M.formatter.bracketed_pasting },
            radian = { cmd = 'radian', formatter = M.formatter.bracketed_pasting },
            ipython = { cmd = 'ipython', formatter = M.formatter.bracketed_pasting },
            python = { cmd = 'python', formatter = M.formatter.trim_empty_lines },
            R = { cmd = 'R', formatter = M.formatter.trim_empty_lines },
            -- bash version >= 4.4 supports bracketed paste mode. but macos
            -- shipped with bash 3.2, so we don't use bracketed paste mode for
            -- bash.
            bash = { cmd = 'bash', formatter = M.formatter.trim_empty_lines },
        },
        close_on_exit = true,
    }
end

M._repls = {}

local function repl_is_valid(repl)
    return repl ~= nil and api.nvim_buf_is_loaded(repl.bufnr)
end

-- rearrange repls such that there's no gap in the repls table.
local function repl_cleanup()
    local valid_repls = {}
    local valid_repls_id = {}
    for id, repl in pairs(M._repls) do
        if repl_is_valid(repl) then
            table.insert(valid_repls_id, id)
        end
    end

    table.sort(valid_repls_id)

    for _, id in ipairs(valid_repls_id) do
        table.insert(valid_repls, M._repls[id])
    end
    M._repls = valid_repls

    for id, repl in pairs(M._repls) do
        -- to avoid name conflict, we add a temp prefix
        api.nvim_buf_set_name(repl.bufnr, string.format('#%s#temp#%d', repl.name, id))
    end

    for id, repl in pairs(M._repls) do
        api.nvim_buf_set_name(repl.bufnr, string.format('#%s#%d', repl.name, id))
    end
end

local function focus_repl(repl)
    if not repl_is_valid(repl) then
        -- if id is nil, print it as -1
        vim.notify [[REPL doesn't exist!]]
        return
    end
    local win = fn.bufwinid(repl.bufnr)
    if win ~= -1 then
        api.nvim_set_current_win(win)
    else
        if type(M._config.wincmd) == 'function' then
            M._config.wincmd(repl.bufnr, repl.name)
        else
            vim.cmd(M._config.wincmd)
            api.nvim_set_current_buf(repl.bufnr)
        end
    end
end

local function create_repl(id, repl_name)
    if repl_is_valid(M._repls[id]) then
        vim.notify(string.format('REPL %d already exists, no new REPL is created', id))
        return
    end

    if not M._config.metas[repl_name] then
        vim.notify 'No REPL palatte is found'
        return
    end

    local bufnr = api.nvim_create_buf(M._config.buflisted, M._config.scratch)
    api.nvim_buf_set_option(bufnr, 'filetype', M._config.ft)

    if type(M._config.wincmd) == 'function' then
        M._config.wincmd(bufnr, repl_name)
    else
        vim.cmd(M._config.wincmd)
        api.nvim_set_current_buf(bufnr)
    end

    local opts = {}
    if M._config.close_on_exit then
        opts.on_exit = function()
            local bufwinid = fn.bufwinid(bufnr)
            while bufwinid ~= -1 do
                api.nvim_win_close(bufwinid, true)
                bufwinid = fn.bufwinid(bufnr)
            end
            -- It is possible that this buffer has already been deleted, before
            -- the process is exit.
            if api.nvim_buf_is_loaded(bufnr) then
                api.nvim_buf_delete(bufnr, { force = true })
            end
            repl_cleanup()
        end
    end

    local term = fn.termopen(M._config.metas[repl_name].cmd, opts)
    api.nvim_buf_set_name(bufnr, string.format('#%s#%d', repl_name, id))
    M._repls[id] = { bufnr = bufnr, term = term, name = repl_name }
end

-- get the id of the closest repl whose name is `NAME` from the `ID`
local function find_closest_repl_from_id_with_name(id, name)
    local closest_id = nil
    local closest_distance = math.huge
    for repl_id, repl in pairs(M._repls) do
        if repl.name == name then
            local distance = math.abs(repl_id - id)
            if distance < closest_distance then
                closest_id = repl_id
                closest_distance = distance
            end
            if distance == 0 then
                break
            end
        end
    end
    return closest_id
end

local function repl_swap(id_1, id_2)
    local repl_1 = M._repls[id_1]
    local repl_2 = M._repls[id_2]
    M._repls[id_1] = repl_2
    M._repls[id_2] = repl_1
    repl_cleanup()
end

-- currently only support line-wise sending in both visual and operator mode.
local function get_lines(mode)
    local begin_mark = mode == 'operator' and "'[" or "'<"
    local end_mark = mode == 'operator' and "']" or "'>"

    local begin_line = fn.getpos(begin_mark)[2]
    local end_line = fn.getpos(end_mark)[2]
    return api.nvim_buf_get_lines(0, begin_line - 1, end_line, false)
end

function M.formatter.bracketed_pasting(lines)
    local open_code = '\27[200~'
    local close_code = '\27[201~'
    local cr = '\13'
    if #lines == 1 then
        return { lines[1] .. cr }
    else
        local new = { open_code .. lines[1] }
        for line = 2, #lines do
            table.insert(new, lines[line])
        end

        table.insert(new, close_code .. cr)

        return new
    end
end

function M.formatter.trim_empty_lines(lines)
    local cr = '\13'
    if #lines == 1 then
        return { lines[1] .. cr }
    else
        local new = {}
        for _, line in ipairs(lines) do
            if line ~= '' then
                table.insert(new, line)
            end
        end

        table.insert(new, cr)
        return new
    end
end

M._send_motion_internal = function(motion)
    -- hack: allow dot-repeat
    if motion == nil then
        vim.go.operatorfunc = [[v:lua.require'REPL'._send_motion_internal]]
        api.nvim_feedkeys('g@', 'ni', false)
    end

    -- NOTE: when using a customized text object/motion, such as those provided
    -- by nvim-treesitter-textobjects, neither vim.v.prevcount nor vim.v.count
    -- is reliable for retrieving the repl id. As a workaround, we can
    -- predefine the id within the keymap itself and not use vim.v.prevcount or
    -- vim.v.count to retrieve the id.
    local id = vim.b[0].repl_id or 1

    if vim.b[0].closest_repl_name then
        id = find_closest_repl_from_id_with_name(id, vim.b[0].closest_repl_name)
    end

    local repl = M._repls[id]

    if not repl_is_valid(repl) then
        vim.notify [[REPL doesn't exist!]]
        return
    end
    local lines = get_lines 'operator'
    lines = M._config.metas[repl.name].formatter(lines)
    fn.chansend(repl.term, lines)
end

M.send_motion = function(closest_repl_name, id)
    if closest_repl_name then
        vim.b[0].closest_repl_name = closest_repl_name
    else
        vim.b[0].closest_repl_name = nil
    end

    if id then
        vim.b[0].repl_id = id
    else
        vim.b[0].repl_id = nil
    end

    vim.go.operatorfunc = [[v:lua.require'REPL'._send_motion_internal]]
    -- Those magic letters 'ni' are coming from Vigemus/iron.nvim and I am not
    -- quite understand the effect of those magic letters.
    api.nvim_feedkeys('g@', 'ni', false)
end

M.setup = function(opts)
    M._config = vim.tbl_deep_extend('force', default_config(), opts or {})
end

api.nvim_create_user_command('REPLStart', function(opts)
    -- if calling the command without any count, we want count to become 1.
    local repl_name = opts.args
    local id = opts.count == 0 and 1 or opts.count
    local repl = M._repls[id]

    if repl_is_valid(repl) then
        vim.notify(string.format('REPL %d already exists', id))
        focus_repl(repl)
        return
    end

    if repl_name == '' then
        local repls = {}
        for name, _ in pairs(M._config.metas) do
            table.insert(repls, name)
        end

        vim.ui.select(repls, {
            prompt = 'Select REPL: ',
        }, function(choice)
            repl_name = choice
            create_repl(id, repl_name)
        end)
    else
        create_repl(id, repl_name)
    end
end, {
    count = true,
    nargs = '?',
    complete = function()
        local metas = {}
        for name, _ in pairs(M._config.metas) do
            table.insert(metas, name)
        end
        return metas
    end,
    desc = [[
Create REPL `i` from the list of available REPLs. If a count is provided, the
REPL will be created with that id, for example `3REPLStart` will create REPL
with id `3`. If no count is provided, the REPL 1 will be created. If an
argument is provided, the REPL will be created with the specified name. If no
argument is provided, the user will be prompted to select a REPL from the list
of available REPLs. If the id is already in use, will focus on the REPL with
that id.
]],
})

api.nvim_create_user_command('REPLCleanup', function()
    repl_cleanup()
end, { desc = 'clean invalid repls, and rearrange the repls order.' })

api.nvim_create_user_command('REPLFocus', function(opts)
    local id = opts.count == 0 and 1 or opts.count
    if opts.args ~= '' then
        id = find_closest_repl_from_id_with_name(id, opts.args)
    end
    focus_repl(M._repls[id])
end, {
    count = true,
    nargs = '?',
    desc = [[
Focus on REPL `i`. The first REPL is the default. If an optional argument is
provided, the function will attempt to focus on the closest REPL with the
specified name. For instance, `3REPLFocus ipython` will focus on the closest
ipython REPL relative to id 3.
]],
})

api.nvim_create_user_command('REPLHide', function(opts)
    local id = opts.count == 0 and 1 or opts.count
    if opts.args ~= '' then
        id = find_closest_repl_from_id_with_name(id, opts.args)
    end
    local repl = M._repls[id]

    if not repl_is_valid(repl) then
        vim.notify [[REPL doesn't exist!]]
        return
    end

    local bufnr = repl.bufnr
    local win = fn.bufwinid(bufnr)
    while win ~= -1 do
        api.nvim_win_close(win, true)
        win = fn.bufwinid(bufnr)
    end
end, {
    count = true,
    nargs = '?',
    desc = [[Hide REPL `i`. The first REPL is the default. If an optional
argument is provided, the function will attempt to hide on the closest REPL
with the specified name. For instance, `3REPLHide ipython` will hide on the
closest ipython REPL relative to id 3.]],
})

api.nvim_create_user_command('REPLClose', function(opts)
    local id = opts.count == 0 and 1 or opts.count
    if opts.args ~= '' then
        id = find_closest_repl_from_id_with_name(id, opts.args)
    end
    local repl = M._repls[id]
    if not repl_is_valid(repl) then
        vim.notify [[REPL doesn't exist!]]
        return
    end
    fn.chansend(repl.term, string.char(4))
end, {
    count = true,
    nargs = '?',
    desc = [[
Close REPL `i`. The first REPL is the default. If an optional argument is
provided, the function will attempt to close the closest REPL with the
specified name. For instance, `3REPLClose ipython` will close the
closest ipython REPL relative to id 3.
]],
})

api.nvim_create_user_command('REPLSwap', function(opts)
    local id_1 = tonumber(opts.fargs[1])
    local id_2 = tonumber(opts.fargs[2])

    local repl_ids = {}
    for id, _ in pairs(M._repls) do
        table.insert(repl_ids, id)
    end

    table.sort(repl_ids)

    if id_1 == nil then
        vim.ui.select(repl_ids, {
            prompt = 'select first REPL',
            format_item = function(item)
                return item .. ' ' .. M._repls[item].name
            end,
        }, function(id1)
            vim.ui.select(repl_ids, {
                prompt = 'select second REPL',
                format_item = function(item)
                    return item .. ' ' .. M._repls[item].name
                end,
            }, function(id2)
                repl_swap(id1, id2)
            end)
        end)
    elseif id_2 == nil then
        vim.ui.select(repl_ids, {
            prompt = 'select second REPL',
            format_item = function(item)
                return item .. ' ' .. M._repls[item].name
            end,
        }, function(id2)
            repl_swap(id_1, id2)
        end)
    else
        repl_swap(id_1, id_2)
    end
end, {
    desc = [[To swap two REPLs, if no REPL ID is provided, you will be prompted
to select both REPLs. If one REPL ID is provided, you will be prompted to
select the second REPL.]],
    nargs = '*',
})

api.nvim_create_user_command('REPLSendVisual', function(opts)
    -- we must use `<ESC>` to clear those marks to mark '> and '> to be able to
    -- access the updated visual range. Those magic letters 'nx' are coming
    -- from Vigemus/iron.nvim and I am not quiet understand the effect of those
    -- magic letters.
    api.nvim_feedkeys('\27', 'nx', false)

    local id = opts.count == 0 and 1 or opts.count
    if opts.args ~= '' then
        id = find_closest_repl_from_id_with_name(id, opts.args)
    end
    local repl = M._repls[id]

    if not repl_is_valid(repl) then
        vim.notify [[REPL doesn't exist!]]
        return
    end
    local lines = get_lines 'visual'
    lines = M._config.metas[repl.name].formatter(lines)
    fn.chansend(repl.term, lines)
end, {
    count = true,
    nargs = '?',
    desc = [[
Send the visual range to REPL `i`. For example, use `REPLSendVisual` or
`3REPLSendVisual` to specify the REPL number. If no number is given, the REPL 1
is the default. If an optional argument is provided, the function will attempt
to send the visual range to the closest REPL with the specified name. For
instance, `3REPLSendVisual ipython` will send the visual range to the closest
ipython REPL relative to id 3.
]],
})

api.nvim_create_user_command('REPLSendLine', function(opts)
    local id = opts.count == 0 and 1 or opts.count
    if opts.args ~= '' then
        id = find_closest_repl_from_id_with_name(id, opts.args)
    end
    local repl = M._repls[id]

    if not repl_is_valid(repl) then
        vim.notify [[REPL doesn't exist!]]
        return
    end
    local line = api.nvim_get_current_line()
    local lines = M._config.metas[repl.name].formatter { line }
    fn.chansend(repl.term, lines)
end, {
    count = true,
    nargs = '?',
    desc = [[
Send current line to the REPL `i`. For example, use `REPLSendLine` or
`3REPLSendLine` to specify the REPL number. If no number is given, REPL 1 is
the default. If an optional argument is provided, the function will attempt to
send the current line to the closest REPL with the specified name. For
instance, `3REPLSendVisual ipython` will send the visual range to the closest
ipython REPL relative to id 3.
]],
})

return M
