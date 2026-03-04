---
name: linear
description: Query and manage Linear issues, projects, and team workflows.
metadata: { "openclaw": { "emoji": "🔷", "requires": { "env": ["LINEAR_API_KEY"] } } }
---

# Linear Integration

You have access to the user's Linear workspace via the Linear GraphQL API.

## Authentication
The API key is available as `LINEAR_API_KEY` in the environment. Use it as a Bearer token.

## API Base URL
`https://api.linear.app/graphql`

All requests MUST include these headers:
```
Authorization: $LINEAR_API_KEY
Content-Type: application/json
```

## Available Actions

### Get current user
```bash
curl -s -X POST 'https://api.linear.app/graphql' \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ viewer { id name email } }"}'
```

### List teams
```bash
curl -s -X POST 'https://api.linear.app/graphql' \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ teams { nodes { id name key } } }"}'
```

### List my assigned issues
```bash
curl -s -X POST 'https://api.linear.app/graphql' \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ viewer { assignedIssues(first: 20) { nodes { id identifier title state { name } priority url } } } }"}'
```

### List issues by team
```bash
curl -s -X POST 'https://api.linear.app/graphql' \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ team(id: \"TEAM_ID\") { issues(first: 20) { nodes { id identifier title state { name } assignee { name } priority } } } }"}'
```

### Search issues
```bash
curl -s -X POST 'https://api.linear.app/graphql' \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ issueSearch(query: \"SEARCH_TERM\", first: 10) { nodes { id identifier title state { name } url } } }"}'
```

### Get a specific issue
```bash
curl -s -X POST 'https://api.linear.app/graphql' \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ issue(id: \"ISSUE_ID\") { id identifier title description state { name } assignee { name } priority comments { nodes { body user { name } createdAt } } } }"}'
```

### Create an issue
```bash
curl -s -X POST 'https://api.linear.app/graphql' \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "mutation { issueCreate(input: { teamId: \"TEAM_ID\", title: \"Issue title\", description: \"Description\" }) { success issue { id identifier url } } }"}'
```

### Update issue state
```bash
curl -s -X POST 'https://api.linear.app/graphql' \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "mutation { issueUpdate(id: \"ISSUE_ID\", input: { stateId: \"STATE_ID\" }) { success } }"}'
```

### List projects
```bash
curl -s -X POST 'https://api.linear.app/graphql' \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ projects(first: 20) { nodes { id name description state } } }"}'
```

## Rules
- Always use `web_fetch` or `exec` with `curl` to make API calls.
- Issue identifiers look like `ENG-123` — use them when displaying issues.
- Priority values: 0=No priority, 1=Urgent, 2=High, 3=Medium, 4=Low.
- Confirm before creating or updating issues.
- When listing issues, show identifier, title, state, and priority.
