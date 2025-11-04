-- 1. Ensure lualine installed

------------------------------------------------------------
-- Git status component replicating powerline_gitstatus
------------------------------------------------------------
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
      })
    end,
  },
}
