---
name: notion
description: Search, create, and update pages and databases in the user's Notion workspace.
metadata: { "openclaw": { "emoji": "📝", "requires": { "env": ["NOTION_API_KEY"] } } }
---

# Notion Integration

You have access to the user's Notion workspace via the Notion API.

## Authentication
The API token is available as `NOTION_API_KEY` in the environment. Use it as a Bearer token in the `Authorization` header.

## API Base URL
`https://api.notion.com/v1`

All requests MUST include these headers:
```
Authorization: Bearer $NOTION_API_KEY
Notion-Version: 2022-06-28
Content-Type: application/json
```

## Available Actions

### Search pages and databases
```bash
curl -s -X POST 'https://api.notion.com/v1/search' \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{"query": "SEARCH_TERM", "page_size": 10}'
```

### Get a page
```bash
curl -s 'https://api.notion.com/v1/pages/PAGE_ID' \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28"
```

### Get page content (blocks)
```bash
curl -s 'https://api.notion.com/v1/blocks/BLOCK_ID/children?page_size=100' \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28"
```

### Create a page
```bash
curl -s -X POST 'https://api.notion.com/v1/pages' \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{
    "parent": {"database_id": "DATABASE_ID"},
    "properties": {
      "Name": {"title": [{"text": {"content": "Page Title"}}]}
    }
  }'
```

### Query a database
```bash
curl -s -X POST 'https://api.notion.com/v1/databases/DATABASE_ID/query' \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{"page_size": 10}'
```

### Append blocks to a page
```bash
curl -s -X PATCH 'https://api.notion.com/v1/blocks/PAGE_ID/children' \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{
    "children": [
      {"object": "block", "type": "paragraph", "paragraph": {"rich_text": [{"type": "text", "text": {"content": "Hello!"}}]}}
    ]
  }'
```

## Rules
- Always use `web_fetch` or `exec` with `curl` to make API calls.
- Parse JSON responses and present data clearly to the user.
- When creating content, confirm the target page/database first.
- For errors, explain what went wrong (e.g. "page not shared with integration").
