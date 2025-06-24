local config = require('scholar.config')

local M = {}

-- Setup function
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
end

-- Fetch DOI data from CrossRef API
local function fetch_doi_data(doi)
  local cmd = string.format("curl -s -H 'Accept: application/json' 'https://api.crossref.org/works/%s'", doi)
  
  if config.debug then
    print("Running command: " .. cmd)
  end
  
  local handle = io.popen(cmd)
  if not handle then
    return nil, "Failed to execute curl command"
  end
  
  local result = handle:read("*a")
  handle:close()
  
  if config.debug then
    print("API response length: " .. #result)
  end
  
  if result == "" then
    return nil, "Empty response from API"
  end
  
  return result, nil
end

-- Parse and extract useful data from JSON
local function parse_doi_data(json_string)
  local success, data = pcall(vim.fn.json_decode, json_string)
  if not success or not data or not data.message then
    return nil, "Failed to parse JSON data"
  end
  
  local work = data.message
  local authors = {}
  
  if work.author then
    for _, author in ipairs(work.author) do
      local name = ""
      if author.given and author.family then
        name = author.given .. " " .. author.family
      elseif author.family then
        name = author.family
      end
      if name ~= "" then
        table.insert(authors, name)
      end
    end
  end
  
  local journal = ""
  if work["container-title"] and #work["container-title"] > 0 then
    journal = work["container-title"][1]
  end
  
  local year = ""
  if work.published and work.published["date-parts"] and #work.published["date-parts"] > 0 then
    year = tostring(work.published["date-parts"][1][1])
  end
  
  return {
    title = work.title and work.title[1] or "Unknown Title",
    authors = table.concat(authors, ", "),
    journal = journal,
    year = year,
    doi = work.DOI or "",
    url = work.URL or ("https://doi.org/" .. (work.DOI or "")),
    reference_count = work["reference-count"] or 0,
    raw_references = work.reference or {}
  }
end

-- Format ALL references - NO TRUNCATION ANYWHERE
local function format_basic_references(raw_references)
  if not raw_references or type(raw_references) ~= "table" then
    return "No references available."
  end
  
  if #raw_references == 0 then
    return "No references found."
  end
  
  local formatted_refs = {}
  
  -- Process EVERY SINGLE reference with no limits
  for i = 1, #raw_references do
    local ref = raw_references[i]
    local ref_text = "[" .. i .. "] "
    
    -- Author
    if ref.author then
      if type(ref.author) == "string" then
        ref_text = ref_text .. ref.author .. ". "
      elseif type(ref.author) == "table" and #ref.author > 0 then
        local first_author = ref.author[1]
        if type(first_author) == "string" then
          ref_text = ref_text .. first_author .. " et al. "
        elseif type(first_author) == "table" and first_author.family then
          ref_text = ref_text .. first_author.family .. " et al. "
        end
      end
    end
    
    -- Title
    local title = ref["article-title"] or ref.title
    if title then
      ref_text = ref_text .. "\"" .. title .. ".\" "
    end
    
    -- Journal
    local journal = ref["journal-title"] or ref.journal
    if journal then
      ref_text = ref_text .. "*" .. journal .. "* "
    end
    
    -- Year
    if ref.year then
      ref_text = ref_text .. "(" .. ref.year .. ")."
    end
    
    -- Clean up spaces
    ref_text = ref_text:gsub("%s+", " "):gsub("%s+$", "")
    
    -- DOI on separate line
    local doi = ref.DOI or ref.doi
    if doi then
      ref_text = ref_text .. "\nDOI: " .. doi
    end
    
    formatted_refs[i] = ref_text
  end
  
  return table.concat(formatted_refs, "\n\n")
end

-- Read template file
local function read_template()
  local current_dir = vim.fn.expand("%:p:h")
  local template_path = current_dir .. "/" .. config.template_file
  
  if config.debug then
    print("Looking for template at: " .. template_path)
  end
  
  local file = io.open(template_path, "r")
  if not file then
    return nil, "Template file not found: " .. template_path
  end
  
  local content = file:read("*a")
  file:close()
  return content
end

-- Replace placeholders in template
local function process_template(template, data)
  local result = template
  
  -- Simple replacements
  result = result:gsub("{{TITLE}}", data.title or "")
  result = result:gsub("{{AUTHORS}}", data.authors or "")
  result = result:gsub("{{JOURNAL}}", data.journal or "")
  result = result:gsub("{{YEAR}}", data.year or "")
  result = result:gsub("{{DOI}}", data.doi or "")
  result = result:gsub("{{URL}}", data.url or "")
  
  -- Format references
  local references = format_basic_references(data.raw_references)
  result = result:gsub("{{REFERENCES}}", references)
  
  if config.debug then
    print("Template processing complete")
  end
  
  return result
end

-- Create filename from paper data
local function create_filename(data)
  local title = data.title:gsub("[^%w%s%-_]", ""):gsub("%s+", "_"):lower()
  local year = data.year ~= "" and ("_" .. data.year) or ""
  return title:sub(1, 50) .. year .. ".md"
end

-- Create a new buffer with content
local function create_buffer_with_content(content, filename)
  -- Create new buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Split the content into lines
  local lines = {}
  for line in content:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  
  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Open buffer in a new window (split)
  vim.cmd("split")
  vim.api.nvim_win_set_buf(0, buf)
  
  -- Set buffer name
  if filename then
    vim.api.nvim_buf_set_name(buf, filename)
  end
  
  print("Created buffer: " .. (filename or "unnamed"))
end

-- Main function to process DOI
function M.process_doi()
  -- Force exit visual mode first
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'x', false)
  
  -- Get the last visual selection
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  
  if start_pos[2] == 0 or end_pos[2] == 0 then
    vim.api.nvim_err_writeln("No text selected. Please select DOI text in visual mode first.")
    return
  end
  
  local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
  if #lines == 0 then
    vim.api.nvim_err_writeln("No lines found in selection")
    return
  end
  
  -- Extract text from selection
  local selected_text = ""
  if #lines == 1 then
    -- Single line - use column positions
    local line = lines[1]
    local start_col = start_pos[3]
    local end_col = end_pos[3]
    selected_text = line:sub(start_col, end_col)
  else
    -- Multiple lines
    selected_text = table.concat(lines, " ")
  end
  
  -- Clean and validate DOI
  local doi = selected_text
  doi = doi:gsub("^%s+", ""):gsub("%s+$", "")  -- trim whitespace
  doi = doi:gsub("^https?://doi%.org/", "")    -- remove URL prefix
  doi = doi:gsub("^doi%s*:%s*", "")           -- remove doi: prefix
  doi = doi:gsub("^DOI%s*:%s*", "")           -- remove DOI: prefix
  
  -- Validate DOI format (basic check)
  if not doi:match("^10%.%d+/") then
    vim.api.nvim_err_writeln("Invalid DOI format. Expected format: 10.xxxx/xxxx")
    return
  end
  
  if config.debug then
    print("Fetching DOI data for: " .. doi)
  end
  
  -- Fetch DOI data
  local raw_data, err = fetch_doi_data(doi)
  if not raw_data then
    vim.api.nvim_err_writeln("Error: " .. err)
    return
  end
  
  if config.debug then
    -- Create buffer with raw JSON data for debugging
    local clean_doi = doi:gsub("[^%w%-_.]", "_")
    local debug_filename = "debug_" .. clean_doi .. ".json"
    create_buffer_with_content(raw_data, debug_filename)
    vim.bo.filetype = "json"
    
    print("Debug mode: Raw JSON data dumped to buffer")
    print("DOI processed: " .. doi)
    print("Debug filename: " .. debug_filename)
  end
  
  -- Parse the data
  local parsed_data, parse_err = parse_doi_data(raw_data)
  if not parsed_data then
    vim.api.nvim_err_writeln("Error parsing data: " .. parse_err)
    return
  end
  
  if config.debug then
    print("Parsed data:")
    for key, value in pairs(parsed_data) do
      if key ~= "raw_references" then
        print("  " .. key .. ": " .. tostring(value))
      end
    end
    if parsed_data.raw_references then
      print("  raw_references: " .. #parsed_data.raw_references .. " items")
    end
  end
  
  -- Try to read and process template
  local template, template_err = read_template()
  if template then
    -- Process template
    local content = process_template(template, parsed_data)
    
    -- Create filename and save in same directory as current buffer
    local filename = create_filename(parsed_data)
    local current_buffer_dir = vim.fn.expand("%:p:h")
    local output_dir = current_buffer_dir .. "/" .. config.output_dir
    local full_path = output_dir .. "/" .. filename
    
    if config.debug then
      print("Current buffer dir: " .. current_buffer_dir)
      print("Output dir: " .. output_dir)
      print("Full path: " .. full_path)
    end
    
    -- Ensure output directory exists
    vim.fn.mkdir(output_dir, "p")
    
    -- Write file first, then open it
    local file = io.open(full_path, "w")
    if file then
      file:write(content)
      file:close()
      
      -- Open the saved file
      vim.cmd("edit " .. vim.fn.fnameescape(full_path))
      print("Created and opened: " .. filename)
    else
      vim.api.nvim_err_writeln("Failed to create file: " .. full_path)
    end
  else
    -- No template found, create buffer with parsed data
    local content = string.format([[# %s

**Authors:** %s
**Journal:** %s
**Year:** %s
**DOI:** %s
**URL:** %s

Found %d references.

## Notes

]], parsed_data.title, parsed_data.authors, parsed_data.journal, parsed_data.year, parsed_data.doi, parsed_data.url, parsed_data.reference_count)
    
    local filename = create_filename(parsed_data)
    
    -- Write to filesystem relative to current buffer
    local current_buffer_dir = vim.fn.expand("%:p:h")
    local full_path = current_buffer_dir .. "/" .. filename
    
    if config.debug then
      print("No template - saving to: " .. full_path)
    end
    
    local file = io.open(full_path, "w")
    if file then
      file:write(content)
      file:close()
      
      -- Open the saved file
      vim.cmd("edit " .. vim.fn.fnameescape(full_path))
      print("Created and opened: " .. filename)
    else
      create_buffer_with_content(content, filename)
      print("Created buffer (no template): " .. filename)
    end
  end
end


return M
