if vim.g.scholar then
  return
end
vim.g.scholar = 1
local scholar = require('scholar')
-- Auto-commands, commands, keymaps go here

-- Set up commands and keymaps
vim.api.nvim_create_user_command('DOIProcess', scholar.process_doi, {
  desc = 'Process selected DOI and create buffer with raw data'
})

vim.keymap.set('v', '<leader>doi', scholar.process_doi, {
  desc = 'Process selected DOI'
})
