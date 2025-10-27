-- Neovim init.lua with lazy.nvim, GitHub Copilot, Copilot Chat, and a Rails-friendly setup
--  - Package manager: folke/lazy.nvim
--  - Copilot core: zbirenbaum/copilot.lua (+ optional completion via copilot-cmp)
--  - Copilot Chat: CopilotC-Nvim/CopilotChat.nvim (code reviews, explanations, fixes, prompts)
--  - Rails DX: vim-rails, Ruby LSP, Treesitter for Ruby/ERB, Git tooling, Telescope
--
-- After installing, run:
--   :Lazy sync
--   :Copilot auth     (authenticate GitHub Copilot)
-- Tip: Use <leader> as the comma key (configured below).
-- Common Copilot Chat mappings:
--   <leader>ct  - Toggle Copilot Chat window
--   <leader>cR  - Ask Copilot to review the current buffer
--   <leader>cD  - Ask Copilot to review the current Git diff (changes)
--   <leader>ce  - Explain the selected code (visual mode supported)
--   <leader>cf  - Fix issues in the selected code (visual mode)
--   <leader>ctt - Generate RSpec tests for selected code
--   <leader>cq  - Open Copilot Chat prompt picker (Telescope)


-- Basic options
vim.g.mapleader = ","                    -- Set leader key to comma
vim.g.maplocalleader = ","               -- Set local leader key to comma

-- Global defaults: 2 spaces
vim.opt.expandtab = true                 -- Use spaces instead of tabs
vim.opt.shiftwidth = 2                   -- Number of spaces for indentation
vim.opt.tabstop = 2                      -- Number of spaces per TAB
vim.opt.softtabstop = 2                  -- Number of spaces for a tab when editing
vim.opt.smartindent = true               -- Smart autoindenting

-- -- Enable filetype-specific behavior
-- vim.cmd('filetype plugin indent on')
--
-- -- Python: 4 spaces (buffer-local)
-- local group = vim.api.nvim_create_augroup('PythonIndent', { clear = true })
-- vim.api.nvim_create_autocmd('FileType', {
--   group = group,
--   pattern = 'python',
--   callback = function()
--     -- Set buffer-local options for Python files
--     vim.opt_local.expandtab = true
--     vim.opt_local.shiftwidth = 4
--     vim.opt_local.tabstop = 4
--     vim.opt_local.softtabstop = 4
--
--     -- Also set these for consistency
--     vim.bo.shiftwidth = 4
--     vim.bo.tabstop = 4
--     vim.bo.softtabstop = 4
--   end,
-- })

vim.opt.relativenumber = false           -- Relative line numbers
vim.opt.number = true                    -- Show line numbers
-- vim.opt.cmdheight = 10                    -- Height of command line
vim.opt.more = false                     -- No more prompts
vim.opt.wrap = false                     -- No line wrapping
vim.opt.termguicolors = true             -- True color support
vim.opt.signcolumn = "yes"               -- Always show sign column
vim.opt.scrolloff = 5                    -- Minimum lines to keep above/below cursor
vim.opt.sidescrolloff = 8                -- Minimum lines to keep before/after cursor
vim.opt.ignorecase = true                -- Case insensitive search
vim.opt.smartcase = true                 -- Case sensitive when uppercase present
vim.opt.updatetime = 250                 -- wait time for swap file and CursorHold
vim.opt.timeoutlen = 400                 -- time to wait for a mapped sequence
vim.opt.cursorline = true                -- highlight current cursor line
vim.opt.cursorcolumn = false             -- highlight current cursor column
vim.opt.splitright = true                -- new vs window opens right
vim.opt.splitbelow = true                -- new sp window opens below
vim.opt.completeopt = "menu,menuone,noselect" -- Better completion experience
vim.opt.swapfile = false                 -- No swap files
vim.opt.backup = false                   -- No backup files
vim.opt.undofile = true                  -- Persistent undo
vim.opt.hlsearch = true                  -- Highlight search results
vim.opt.incsearch = true                 -- Incremental search
vim.opt.clipboard = "unnamedplus"        -- Use system clipboard
vim.opt.mouse = ""                       -- Disable mouse support
vim.opt.list = true                      -- make space chars visible
vim.opt.listchars = { tab = "» ", trail = "·", extends = "›", precedes = "‹" } -- visible chars
vim.opt.encoding = "utf-8"               -- Set default encoding
vim.opt.fileencoding = "utf-8"           -- default file encoding
vim.opt.fileencodings = "utf-8,ucs-bom,latin1" -- file encodings to try

-- Set Python and Ruby host programs
vim.g.python3_host_prog = '/Users/edgar/.pve/py3nvim/bin/python'
vim.g.ruby_host_prog = '/Users/edgar/.rbenv/versions/3.4.5/bin/neovim-ruby-host'

require("config.lazy")

PrintDiagnostics = function()
  local line_diagnostics = vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })
  if not line_diagnostics or #line_diagnostics == 0 then
    return
  end

  local diagnostic_message = ""
  for _i,diagnostic in ipairs(line_diagnostics) do
    if not (string.find(diagnostic_message, diagnostic.message, 1, true) ~= nil) then
      if diagnostic_message ~= "" then
        diagnostic_message = diagnostic_message .. " | " -- Separator for multiple diagnostics
      end
      diagnostic_message = diagnostic_message .. string.format("%s: %s", diagnostic.severity, diagnostic.message or "")
    end
  end
  if #diagnostic_message > vim.o.columns then
    diagnostic_message = diagnostic_message:sub(1, vim.o.columns - 4) .. "..."
  end
  vim.api.nvim_echo({{diagnostic_message, "Normal"}}, false, {})
end

vim.cmd [[autocmd! CursorHold,CursorHoldI * lua PrintDiagnostics()]]

-----------------------------------------------------------
-- Optional aesthetics (you can replace with your favorite theme)
-----------------------------------------------------------
--- Set colorscheme
vim.cmd([[colorscheme tokyonight]])

-- vim.api.nvim_set_hl(0, "IndentBlanklineChar", { bg = "NONE" })
-- vim.api.nvim_set_hl(0, "IndentBlanklineContextChar", { bg = "NONE" })

-- Minimal statusline to keep things clean without extra plugins
-- vim.opt.laststatus = 3
-- vim.opt.showmode = true

-- This is your opts table
require("telescope").setup {
  extensions = {
    ["ui-select"] = {
      require("telescope.themes").get_dropdown {
        -- even more opts
      }

      -- pseudo code / specification for writing custom displays, like the one
      -- for "codeactions"
      -- specific_opts = {
      --   [kind] = {
      --     make_indexed = function(items) -> indexed_items, width,
      --     make_displayer = function(widths) -> displayer
      --     make_display = function(displayer) -> function(e)
      --     make_ordinal = function(e) -> string
      --   },
      --   -- for example to disable the custom builtin "codeactions" display
      --      do the following
      --   codeactions = false,
      -- }
    }
  }
}
-- To get ui-select loaded and working with telescope, you need to call
-- load_extension, somewhere after setup function:
require("telescope").load_extension("ui-select")

local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
end

map("n", "<leader>tt", "<cmd>split<cr><cmd>term<cr>i", "Open Terminal")

-- Telescope quick mappings
map("n", "<C-p>", "<cmd>Telescope find_files<cr>", "Find files")
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", "Find files")
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", "Live grep (ripgrep)")
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", "Buffers")
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", "Help tags")
map("n", "<leader>fp", "<cmd>Telescope git_files<cr>", "Git files")

-----------------------------------------------------------
-- Rails convenience keymaps (non-intrusive)
-----------------------------------------------------------
-- Quick open files in Rails projects if using vim-rails (e.g., :Econtroller users)
map("n", "<leader>rr", ":Rails<CR>", "Rails: Show commands")
map("n", "<leader>rg", ":Egenerator<Space>", "Rails: Open generator")
map("n", "<leader>rm", ":Emodel<Space>", "Rails: Open model")
map("n", "<leader>rc", ":Econtroller<Space>", "Rails: Open controller")
map("n", "<leader>rv", ":Eview<Space>", "Rails: Open view")
map("n", "<leader>rs", ":Espec<Space>", "Rails: Open spec")

-- Fix ESC key on iTerm2
if vim.fn.has('nvim') == 1 then
  vim.api.nvim_set_keymap('t', '<Esc>', '<C-\\><C-n>', {noremap = true}) -- This is to get out of terminal mode
  vim.api.nvim_set_keymap('t', '<C-v><Esc>', '<Esc>', {noremap = true}) -- This is to fix the esc key
end

-- Window Switching
vim.api.nvim_set_keymap('n', '<C-h>', '<c-w>h', {noremap = true})
vim.api.nvim_set_keymap('n', '<C-j>', '<c-w>j', {noremap = true})
vim.api.nvim_set_keymap('n', '<C-k>', '<c-w>k', {noremap = true})
vim.api.nvim_set_keymap('n', '<C-l>', '<c-w>l', {noremap = true})

if vim.fn.has('nvim') == 1 then
  vim.api.nvim_set_keymap('t', '<C-h>', '<c-\\><c-n><c-w>h', {noremap = true})
  vim.api.nvim_set_keymap('t', '<C-j>', '<c-\\><c-n><c-w>j', {noremap = true})
  vim.api.nvim_set_keymap('t', '<C-k>', '<c-\\><c-n><c-w>k', {noremap = true})
  vim.api.nvim_set_keymap('t', '<C-l>', '<c-\\><c-n><c-w>l', {noremap = true})
end

-----------------------------------------------------------
-- Final notes:
-- 1) Authenticate Copilot once: :Copilot auth
-- 2) If Copilot Chat fails on first run, ensure you have a valid Copilot subscription
--    and that :Copilot status shows “Authenticated”.
-- 3) For code reviews on your changes, try:
--      - <leader>cD (Git diff review)
--      - <leader>cR (Buffer review)
-- 4) Use visual-mode maps for selection-aware prompts (explain/fix/tests).
-----------------------------------------------------------
