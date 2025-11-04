-- Example Neovim init (extract pieces into your existing config as needed)

-- 1. Ensure lualine installed (example with lazy.nvim; change if using packer):
-- require("lazy").setup({
--   { "nvim-lualine/lualine.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },
-- })

------------------------------------------------------------
-- Git status component replicating powerline_gitstatus
------------------------------------------------------------
local git_component = (function()
  local uv = vim.loop
  local M = {}
  local cache = {}
  local running = {}
  local debounce_timer = nil

  local function is_git_repo(buf)
    local fname = vim.api.nvim_buf_get_name(buf)
    if fname == "" then return nil end
    local dir = vim.fn.fnamemodify(fname, ":p:h")
    -- Use git rev-parse to get root (sync but cached)
    local git_root = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })[1]
    if vim.v.shell_error ~= 0 or not git_root or git_root == "" then
      return nil
    end
    return git_root
  end

  local function file_exists(path)
    local stat = uv.fs_stat(path)
    return stat and stat.type == "file"
  end

  local function detect_operation(git_dir)
    local ops = {
      { file = "rebase-merge", label = "REBASING" },
      { file = "rebase-apply", label = "REBASING" },
      { file = "MERGE_HEAD",   label = "MERGING" },
      { file = "CHERRY_PICK_HEAD", label = "CHERRY" },
      { file = "REVERT_HEAD",  label = "REVERT" },
      { file = "BISECT_LOG",   label = "BISECT" },
    }
    for _, op in ipairs(ops) do
      if file_exists(git_dir .. "/" .. op.file) then
        return op.label
      end
    end
    return nil
  end

  local function parse_status(output_lines)
    local res = {
      branch = "",
      upstream = "",
      ahead = 0,
      behind = 0,
      staged = 0,
      unstaged = 0,
      untracked = 0,
      conflicted = 0,
    }
    for _, line in ipairs(output_lines) do
      if vim.startswith(line, "#") then
        if line:match("^# branch.head") then
          res.branch = line:match("branch.head%s+(.*)") or ""
          if res.branch == "(detached)" then
            res.branch = "DETACHED"
          end
        elseif line:match("^# branch.upstream") then
          res.upstream = line:match("branch.upstream%s+(.*)") or ""
        elseif line:match("^# branch.ab") then
          local a, b = line:match("branch.ab%s+%+(%d+)%s%-(%d+)")
          res.ahead = tonumber(a) or 0
          res.behind = tonumber(b) or 0
        end
      else
        local first = line:sub(1,1)
        if first == "1" or first == "2" then
          -- Format: 1 <XY> ...
          local xy = line:match("^%d%s+(..)")
          if xy then
            local x = xy:sub(1,1)
            local y = xy:sub(2,2)
            if x ~= "." and x ~= "?" then res.staged = res.staged + 1 end
            if y ~= "." and y ~= "?" then res.unstaged = res.unstaged + 1 end
          end
        elseif first == "u" then
          res.conflicted = res.conflicted + 1
        elseif first == "?" then
          res.untracked = res.untracked + 1
        end
      end
    end
    return res
  end

  local function run_cmd(cwd, args, callback)
    local stdout = uv.new_pipe(false)
    local stderr = uv.new_pipe(false)
    local output = {}
    local err_output = {}

    local handle
    handle = uv.spawn("git", { args = args, cwd = cwd, stdio = { nil, stdout, stderr } }, function(code)
      stdout:read_stop()
      stderr:read_stop()
      stdout:close()
      stderr:close()
      handle:close()
      callback(code, output, err_output)
    end)

    if not handle then
      callback(1, {}, { "spawn failed" })
      return
    end

    stdout:read_start(function(err, data)
      if err then return end
      if data then
        for line in data:gmatch("[^\r\n]+") do
          table.insert(output, line)
        end
      end
    end)

    stderr:read_start(function(_err, data)
      if data then
        for line in data:gmatch("[^\r\n]+") do
          table.insert(err_output, line)
        end
      end
    end)
  end

  local function update_repo(root)
    if running[root] then return end
    running[root] = true

    run_cmd(root, { "status", "--porcelain=2", "-b" }, function(code, lines, _)
      local result = nil
      if code == 0 then
        result = parse_status(lines)
      else
        running[root] = false
        return
      end

      -- Stash count (separate command)
      run_cmd(root, { "rev-list", "--walk-reflogs", "--count", "refs/stash" }, function(_c2, lines2, _)
        local stash = tonumber(lines2[1]) or 0
        local git_dir = root .. "/.git"
        local op = detect_operation(git_dir)
        cache[root] = {
          data = result,
          stash = stash,
          op = op,
          ts = vim.loop.now(),
        }
        running[root] = false
        -- Trigger lualine redraw
        pcall(vim.cmd, "redrawstatus")
      end)
    end)
  end

  local function schedule_update()
    if debounce_timer then
      debounce_timer:stop()
      debounce_timer:close()
      debounce_timer = nil
    end
    debounce_timer = uv.new_timer()
    debounce_timer:start(200, 0, function()
      vim.schedule(function()
        local buf = vim.api.nvim_get_current_buf()
        local root = is_git_repo(buf)
        if root then update_repo(root) end
      end)
    end)
  end

  -- Autocommands to refresh
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "FocusGained", "CursorHold" }, {
    group = vim.api.nvim_create_augroup("GitStatusLualine", { clear = true }),
    callback = function() schedule_update() end
  })

  local symbols = {
    branch = "", -- or 
    ahead = "↑",
    behind = "↓",
    staged = "●",
    unstaged = "✚",
    untracked = "…",
    conflicted = "",
    stash = "⚑",
    clean = "✓",
  }

  local function fmt_segment(d)
    if not d then return "" end
    local parts = {}

    -- Branch
    if d.branch and d.branch ~= "" then
      table.insert(parts, symbols.branch .. d.branch)
    else
      table.insert(parts, symbols.branch .. "?")
    end

    -- Operation
    if d.op then
      table.insert(parts, "(" .. d.op .. ")")
    end

    -- Ahead/Behind
    if (d.ahead and d.ahead > 0) or (d.behind and d.behind > 0) then
      local ab = ""
      if d.ahead > 0 then ab = ab .. symbols.ahead .. d.ahead end
      if d.behind > 0 then
        if #ab > 0 then ab = ab .. " " end
        ab = ab .. symbols.behind .. d.behind
      end
      table.insert(parts, ab)
    end

    -- Counters
    local counters = {}
    if d.staged > 0 then table.insert(counters, symbols.staged .. d.staged) end
    if d.unstaged > 0 then table.insert(counters, symbols.unstaged .. d.unstaged) end
    if d.untracked > 0 then table.insert(counters, symbols.untracked .. d.untracked) end
    if d.conflicted > 0 then table.insert(counters, symbols.conflicted .. d.conflicted) end
    if #counters > 0 then
      table.insert(parts, table.concat(counters, " "))
    else
      -- Clean working tree hint
      table.insert(parts, symbols.clean)
    end

    if d.stash and d.stash > 0 then
      table.insert(parts, symbols.stash .. d.stash)
    end

    return table.concat(parts, " ")
  end

  function M.component()
    local buf = vim.api.nvim_get_current_buf()
    local root = is_git_repo(buf)
    if not root then return "" end
    local entry = cache[root]
    if not entry then
      -- First time: kick off update
      update_repo(root)
      return "…git"
    end
    return fmt_segment({
      branch = entry.data.branch,
      ahead = entry.data.ahead,
      behind = entry.data.behind,
      staged = entry.data.staged,
      unstaged = entry.data.unstaged,
      untracked = entry.data.untracked,
      conflicted = entry.data.conflicted,
      stash = entry.stash,
      op = entry.op,
    })
  end

  return M
end)()

return  {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup({
        options = {
          globalstatus = false,
          theme  = 'powerline',
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = {
            git_component.component, -- Our custom git status
          },
          lualine_c = {
            { "filename", path = 1 },
          },
          lualine_x = {
            "encoding",
            { "fileformat", symbols = { unix = "LF", dos = "CRLF", mac = "CR" } },
            "filetype",
          },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { "filename" },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {},
        },
      })
    end,
  },
}
