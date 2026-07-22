-- Echte Tabs mit Breite 2 fuer C++ (ueberschreibt vim-sleuth)
vim.bo.expandtab = false
vim.bo.tabstop = 2
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 0

-- Eingebautes C-Indent nutzen (Treesitter-Indent ist fuer c/cpp deaktiviert)
vim.bo.cindent = true
