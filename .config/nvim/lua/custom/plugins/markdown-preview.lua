return {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown", "mdx" },
    -- Node-basierter Build statt der vorkompilierten Binary (deren WebSocket
    -- einfriert). Braucht node/npm im PATH.
    build = "cd app && npm install",
    init = function()
        vim.g.mkdp_filetypes = { "markdown", "mdx" }
        -- 0 = Live-Refresh beim Tippen/Cursorbewegung (statt nur beim Speichern)
        vim.g.mkdp_refresh_slow = 0
        -- Vorschau offen lassen, auch wenn der Buffer gewechselt wird
        vim.g.mkdp_auto_close = 0
    end,
}
