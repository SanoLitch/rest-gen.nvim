-- .luacheckrc

-- Define global variables provided by Neovim
globals = {
  "vim",
}

-- Ignore warnings for unused arguments, common in callbacks
ignore = {
  "631", -- unused argument
}

-- Set a reasonable line length
max_line_length = 120
