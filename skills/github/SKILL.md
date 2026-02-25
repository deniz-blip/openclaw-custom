---
name: github
description: Manage repositories, issues, pull requests, and code on GitHub.
metadata: { "openclaw": { "emoji": "🐙", "requires": { "env": ["GITHUB_TOKEN"] } } }
---

# GitHub Integration

You have access to the user's GitHub account via the GitHub REST API.

## Authentication
The personal access token is available as `GITHUB_TOKEN` in the environment. Use it as a Bearer token.

## API Base URL
`https://api.github.com`

All requests MUST include these headers:
```
Authorization: Bearer $GITHUB_TOKEN
Accept: application/vnd.github+json
X-GitHub-Api-Version: 2022-11-28
```

## Available Actions

### List user's repositories
```bash
curl -s 'https://api.github.com/user/repos?per_page=30&sort=updated' \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json"
```

### Get a repository
```bash
curl -s 'https://api.github.com/repos/OWNER/REPO' \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json"
```

### List issues
```bash
curl -s 'https://api.github.com/repos/OWNER/REPO/issues?state=open&per_page=20' \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json"
```

### Create an issue
```bash
curl -s -X POST 'https://api.github.com/repos/OWNER/REPO/issues' \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "Content-Type: application/json" \
  -d '{"title": "Issue Title", "body": "Issue description"}'
```

### List pull requests
```bash
curl -s 'https://api.github.com/repos/OWNER/REPO/pulls?state=open&per_page=20' \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json"
```

### Get file contents
```bash
curl -s 'https://api.github.com/repos/OWNER/REPO/contents/PATH' \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json"
```

### Search repositories
```bash
curl -s 'https://api.github.com/search/repositories?q=QUERY&per_page=10' \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json"
```

### Search code
```bash
curl -s 'https://api.github.com/search/code?q=QUERY+repo:OWNER/REPO' \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json"
```

## Rules
- Always use `web_fetch` or `exec` with `curl` to make API calls.
- When listing repos, show name, description, language, and last updated.
- For issues/PRs, show number, title, state, and author.
- Confirm before creating or modifying resources.
- Handle pagination when results exceed page size.
