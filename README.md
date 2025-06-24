# scholar.nvim

Fetch scholarly artcile metadata 

## What Is Scholar?

`scholar.nvim` is a plugin to expedite note taking for shcolarly articles. The plugin will generate templated note files and insert meta data such as title, authors, and references. 

## Table of Contents

- [Getting Started](#getting-started)
- [Usage](#usage)
- [Default Mappings](#default-mappings)

## Getting Started

No dependencies.

### Installation

```viml
Plug 'asward/scholar.nvim'
```

Using [dein](https://github.com/Shougo/dein.vim)

```viml
call dein#add('asward/scholar.nvim')
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'asward/scholar.nvim'
-- or                            
  requires = { {'asward/scholar.nvim'} }
}
```

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- init.lua:
    {
    'asward/scholar.nvim'
    }

-- plugins/scholar.lua:
return {
    'asward/scholar.nvim'
    }
```

## Usage

Using visual mode select text of a doi.org string and activate the plugin.


## Default Mappings

Mappings are fully customizable.
Many familiar mapping patterns are set up as defaults.

| Mappings       | Action                                                    |
| -------------- | --------------------------------------------------------- |
| `<leader>doi`  | Fetch from DOI.org                                        |
