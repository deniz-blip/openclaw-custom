---
name: jira
description: Search, create, and update Jira issues and manage project workflows.
metadata: { "openclaw": { "emoji": "🎯", "requires": { "env": ["JIRA_BASE_URL", "JIRA_EMAIL", "JIRA_API_TOKEN"] } } }
---

# Jira Integration

You have access to the user's Jira instance via the Jira REST API v3.

## Authentication
Credentials are available as environment variables:
- `JIRA_BASE_URL` — e.g. `https://yourcompany.atlassian.net`
- `JIRA_EMAIL` — Atlassian account email
- `JIRA_API_TOKEN` — API token from id.atlassian.com

Authentication uses HTTP Basic auth with `JIRA_EMAIL:JIRA_API_TOKEN` base64-encoded, or pass via curl's `-u` flag.

## Available Actions

### Get current user
```bash
curl -s "$JIRA_BASE_URL/rest/api/3/myself" \
  -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Accept: application/json"
```

### List projects
```bash
curl -s "$JIRA_BASE_URL/rest/api/3/project/search?maxResults=20" \
  -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Accept: application/json"
```

### Search issues (JQL)
```bash
curl -s "$JIRA_BASE_URL/rest/api/3/search?jql=assignee%3DcurrentUser()%20AND%20status!%3DDone&maxResults=20" \
  -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Accept: application/json"
```
Common JQL examples:
- My open issues: `assignee=currentUser() AND status!=Done`
- By project: `project=PROJ AND status="In Progress"`
- By text: `text~"search term"`

### Get a specific issue
```bash
curl -s "$JIRA_BASE_URL/rest/api/3/issue/ISSUE_KEY" \
  -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Accept: application/json"
```
ISSUE_KEY format: `PROJ-123`

### Create an issue
```bash
curl -s -X POST "$JIRA_BASE_URL/rest/api/3/issue" \
  -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "project": {"key": "PROJ"},
      "summary": "Issue summary",
      "description": {"type": "doc", "version": 1, "content": [{"type": "paragraph", "content": [{"type": "text", "text": "Description"}]}]},
      "issuetype": {"name": "Task"}
    }
  }'
```

### Update an issue
```bash
curl -s -X PUT "$JIRA_BASE_URL/rest/api/3/issue/ISSUE_KEY" \
  -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"fields": {"summary": "Updated summary"}}'
```

### Add a comment
```bash
curl -s -X POST "$JIRA_BASE_URL/rest/api/3/issue/ISSUE_KEY/comment" \
  -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"body": {"type": "doc", "version": 1, "content": [{"type": "paragraph", "content": [{"type": "text", "text": "Comment text"}]}]}}'
```

### Get available transitions (statuses)
```bash
curl -s "$JIRA_BASE_URL/rest/api/3/issue/ISSUE_KEY/transitions" \
  -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Accept: application/json"
```

### Transition an issue (change status)
```bash
curl -s -X POST "$JIRA_BASE_URL/rest/api/3/issue/ISSUE_KEY/transitions" \
  -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"transition": {"id": "TRANSITION_ID"}}'
```

## Rules
- Always use `web_fetch` or `exec` with `curl` to make API calls.
- Always fetch transitions before changing issue status — transition IDs vary per project.
- Issue descriptions use Atlassian Document Format (ADF) — use the doc/paragraph/text structure shown above.
- Confirm before creating or updating issues.
- When listing issues, show key, summary, status, and assignee.
