# scholar.nvim

Fetch scholarly artcile metadata 

## What Is Scholar?

`scholar.nvim` is a plugin to expedite note taking for shcolarly articles. The plugin will generate templated note files and insert meta data such as title, authors, and references. 

## Table of Contents

- [Getting Started](#getting-started)
- [Features](#features)
- [How It Works](#how-it-works)
- [Data Retrieved](#data-retrieved)
- [Template System](#template-system)
- [Usage](#usage)
- [Default Mappings](#default-mappings)

## Getting Started

Scholar.nvim has no dependencies.

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

### Configuration

```lua
require('scholar').setup({
  template_file = "template.md",  -- Template filename
  output_dir = "papers",          -- Output directory for generated files
  debug = false                   -- Enable verbose debugging
})
```

## Features

- **DOI Processing**: Select any DOI in visual mode and automatically fetch complete paper metadata
- **Reference Extraction**: Retrieves and formats ALL references from academic papers (no truncation)
- **Template System**: Customizable Markdown templates for consistent note formatting
- **Automatic File Creation**: Generates properly named files based on paper titles and years

## How It Works

1. **Select a DOI** in visual mode (supports various formats: `10.1000/xyz`, `doi:10.1000/xyz`, `https://doi.org/10.1000/xyz`)
2. **Run the command** to fetch paper data from CrossRef API
3. **Get formatted output** with title, authors, journal, year, and complete reference list
4. **File is created** in your specified output directory with a clean filename

## Data Retrieved

For each paper, Scholar.nvim fetches:
- Title and authors
- Journal name and publication year
- DOI and URL
- Complete reference list with DOIs when available
- Reference count statistics


## Template System

Templates support these placeholders:
- `{{TITLE}}` - Paper title
- `{{AUTHORS}}` - Comma-separated author list
- `{{JOURNAL}}` - Journal name
- `{{YEAR}}` - Publication year
- `{{DOI}}` - Digital Object Identifier
- `{{URL}}` - Paper URL
- `{{REFERENCES}}` - Complete formatted reference list

Templates are searched in:
1. Current directory
2. `.scholar/` directory (recursively up the directory tree)

## Usage

1. Install the plugin
2. Create a template file (optional)
3. Select any DOI text in visual mode
4. Run `:lua require('scholar').process_doi()`

Perfect for researchers, students, and academics who need to quickly gather paper metadata and references for literature reviews or research notes.





## Default Mappings

Mappings are fully customizable.
Many familiar mapping patterns are set up as defaults.

| Mappings       | Action                                                    |
| -------------- | --------------------------------------------------------- |
| `<leader>doi`  | Fetch from DOI.org                                        |
