-- MDX file support: filetype detection, syntax highlighting, and treesitter
return {
  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      -- Register .mdx filetype and use markdown treesitter for highlighting
      vim.filetype.add {
        extension = {
          mdx = 'mdx',
        },
      }

      vim.treesitter.language.register('markdown', 'mdx')

      -- Ensure markdown parsers are installed for MDX highlighting
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'markdown', 'markdown_inline' })
    end,
  },
}
