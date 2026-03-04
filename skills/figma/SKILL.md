---
name: figma
description: Inspect Figma design files, export assets, and analyze design systems.
metadata: { "openclaw": { "emoji": "🎨", "requires": { "env": ["FIGMA_TOKEN"] } } }
---

# Figma Integration

You have read-only access to the user's Figma account via the Figma REST API.

## Authentication
The personal access token is available as `FIGMA_TOKEN` in the environment. Use it as a custom header.

## API Base URL
`https://api.figma.com`

All requests MUST include this header:
```
X-Figma-Token: $FIGMA_TOKEN
```

## Available Actions

### Get current user
```bash
curl -s 'https://api.figma.com/v1/me' \
  -H "X-Figma-Token: $FIGMA_TOKEN"
```

### Get a file (structure + document tree)
```bash
curl -s 'https://api.figma.com/v1/files/FILE_KEY' \
  -H "X-Figma-Token: $FIGMA_TOKEN"
```
The `FILE_KEY` is the alphanumeric ID in the Figma file URL (e.g. `https://figma.com/file/FILE_KEY/...`).

### Get specific nodes from a file
```bash
curl -s 'https://api.figma.com/v1/files/FILE_KEY/nodes?ids=NODE_ID1,NODE_ID2' \
  -H "X-Figma-Token: $FIGMA_TOKEN"
```

### Export assets (render nodes as images)
```bash
curl -s 'https://api.figma.com/v1/images/FILE_KEY?ids=NODE_ID1,NODE_ID2&format=png&scale=2' \
  -H "X-Figma-Token: $FIGMA_TOKEN"
```
Supported formats: `png`, `svg`, `jpg`, `pdf`. Scale: `0.5`–`4`.

### Get image fills (URLs for raster images embedded in a file)
```bash
curl -s 'https://api.figma.com/v1/files/FILE_KEY/images' \
  -H "X-Figma-Token: $FIGMA_TOKEN"
```

### List published components in a file
```bash
curl -s 'https://api.figma.com/v1/files/FILE_KEY/components' \
  -H "X-Figma-Token: $FIGMA_TOKEN"
```

### List published styles in a file
```bash
curl -s 'https://api.figma.com/v1/files/FILE_KEY/styles' \
  -H "X-Figma-Token: $FIGMA_TOKEN"
```

### List comments on a file
```bash
curl -s 'https://api.figma.com/v1/files/FILE_KEY/comments' \
  -H "X-Figma-Token: $FIGMA_TOKEN"
```

### List projects in a team
```bash
curl -s 'https://api.figma.com/v1/teams/TEAM_ID/projects' \
  -H "X-Figma-Token: $FIGMA_TOKEN"
```
The `TEAM_ID` is found in the Figma team URL.

### List files in a project
```bash
curl -s 'https://api.figma.com/v1/projects/PROJECT_ID/files' \
  -H "X-Figma-Token: $FIGMA_TOKEN"
```

## Rules
- Always use `web_fetch` or `exec` with `curl` to make API calls.
- This integration is read-only — do not attempt to create or modify Figma files.
- When presenting file structure, summarize key frames and pages rather than dumping the full tree.
- For exports, return the image URLs from the API response — the user can open them directly.
- When the user provides a Figma URL, extract the FILE_KEY from it automatically.
- Handle pagination: responses may include `cursor` for large result sets.
