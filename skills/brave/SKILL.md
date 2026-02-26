---
name: brave
description: Search the web using Brave Search API. Use for web search, fact-checking, and finding current information.
metadata: { "openclaw": { "emoji": "🔍", "requires": { "env": ["BRAVE_API_KEY"] } } }
---

# Brave Search (Web Search)

You can search the web via the Brave Search API. Use this for live information, web search, or when the user asks to look something up online.

## Authentication

The API key is in the environment as `BRAVE_API_KEY`. Send it in the request header.

## API

- **Base URL**: `https://api.search.brave.com/res/v1`
- **Auth header**: `X-Subscription-Token: $BRAVE_API_KEY`

## Web search

```bash
curl -s -G 'https://api.search.brave.com/res/v1/web/search' \
  --data-urlencode "q=SEARCH_QUERY" \
  -H "X-Subscription-Token: $BRAVE_API_KEY"
```

Optional query params: `count` (1–20), `offset`, `safesearch` (off, moderate, strict).

Use the JSON response to answer the user (titles, descriptions, URLs).
