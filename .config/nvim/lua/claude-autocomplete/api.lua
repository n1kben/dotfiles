local curl = require("plenary.curl")
local config = require("claude-autocomplete.config")

local M = {}

local function get_api_key()
  local api_key = vim.env.ANTHROPIC_API_KEY
  if not api_key then
    vim.notify("ANTHROPIC_API_KEY environment variable not set", vim.log.levels.ERROR)
    return nil
  end
  return api_key
end

local function build_prompt(reference_file, current_file, cursor_pos)
  local cfg = config.config
  
  local example_rescript = ""
  local example_typescript = ""
  
  if cfg.example_rescript_file then
    local file = io.open(cfg.example_rescript_file, "r")
    if file then
      example_rescript = file:read("*a")
      file:close()
    end
  end
  
  if cfg.example_typescript_file then
    local file = io.open(cfg.example_typescript_file, "r")
    if file then
      example_typescript = file:read("*a")
      file:close()
    end
  end
  
  local system_prompt = string.format([[You are an expert at migrating rescript code to typescript. You have been tasked by the user to autocomplete what they type. Only return the completed text, not the full file.

Here is an example

File to migrate:
```rescript
%s
```

Migrated file:
```typescript
%s
```]], example_rescript, example_typescript)
  
  local user_content = string.format([[Here is the reference file that the user wants to migrate:
```rescript
%s
```

Here is the current file that the user is migrating, the cursor will be represented by a carrot ^
```typescript
%s
```]], reference_file, current_file)
  
  return system_prompt, user_content
end

function M.get_completion(reference_content, current_content, cursor_pos, callback)
  local api_key = get_api_key()
  if not api_key then
    return
  end
  
  local system_prompt, user_content = build_prompt(reference_content, current_content, cursor_pos)
  
  local body = vim.json.encode({
    model = "claude-haiku-4-5-20251001",
    max_tokens = 5827,
    temperature = 1,
    system = system_prompt,
    messages = {
      {
        role = "user",
        content = {
          {
            type = "text",
            text = user_content
          }
        }
      }
    }
  })
  
  curl.post("https://api.anthropic.com/v1/messages", {
    headers = {
      ["Content-Type"] = "application/json",
      ["x-api-key"] = api_key,
      ["anthropic-version"] = "2023-06-01"
    },
    body = body,
    callback = vim.schedule_wrap(function(response)
      if response.status == 200 then
        local ok, data = pcall(vim.json.decode, response.body)
        if ok and data.content and data.content[1] and data.content[1].text then
          callback(data.content[1].text)
        else
          vim.notify("Failed to parse Claude response", vim.log.levels.ERROR)
        end
      else
        vim.notify("Claude API error: " .. response.status, vim.log.levels.ERROR)
      end
    end)
  })
end

return M