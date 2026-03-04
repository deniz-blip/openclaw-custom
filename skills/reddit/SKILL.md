---
name: reddit
description: Browse, search, and read Reddit posts, comments, and subreddits.
metadata: { "openclaw": { "emoji": "🤖", "requires": { "env": ["REDDIT_CLIENT_ID", "REDDIT_CLIENT_SECRET"] } } }
---

# Reddit Integration

You have read-only access to Reddit via the Reddit API. Authentication uses app-only OAuth (no user account required).

## Authentication
Credentials are available as `REDDIT_CLIENT_ID` and `REDDIT_CLIENT_SECRET`. Obtain a bearer token first, then use it for all subsequent requests.

### Step 1: Get access token
```bash
curl -s -X POST 'https://www.reddit.com/api/v1/access_token' \
  -u "$REDDIT_CLIENT_ID:$REDDIT_CLIENT_SECRET" \
  -H "User-Agent: clawoop-bot/1.0" \
  -d 'grant_type=client_credentials'
```
Returns `{"access_token": "TOKEN", "expires_in": 3600, ...}`. Store the token and use it in all subsequent requests. Refresh when expired.

## API Base URL
`https://oauth.reddit.com`

All subsequent requests MUST include:
```
Authorization: Bearer ACCESS_TOKEN
User-Agent: clawoop-bot/1.0
```

## Available Actions

### Get hot posts from a subreddit
```bash
curl -s 'https://oauth.reddit.com/r/SUBREDDIT/hot?limit=10' \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "User-Agent: clawoop-bot/1.0"
```

### Get new posts from a subreddit
```bash
curl -s 'https://oauth.reddit.com/r/SUBREDDIT/new?limit=10' \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "User-Agent: clawoop-bot/1.0"
```

### Get top posts (time: hour, day, week, month, year, all)
```bash
curl -s 'https://oauth.reddit.com/r/SUBREDDIT/top?t=week&limit=10' \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "User-Agent: clawoop-bot/1.0"
```

### Search across Reddit
```bash
curl -s 'https://oauth.reddit.com/search?q=QUERY&sort=relevance&limit=10' \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "User-Agent: clawoop-bot/1.0"
```

### Search within a subreddit
```bash
curl -s 'https://oauth.reddit.com/r/SUBREDDIT/search?q=QUERY&restrict_sr=true&limit=10' \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "User-Agent: clawoop-bot/1.0"
```

### Get post comments
```bash
curl -s 'https://oauth.reddit.com/r/SUBREDDIT/comments/POST_ID?limit=20&depth=2' \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "User-Agent: clawoop-bot/1.0"
```

### Get subreddit info
```bash
curl -s 'https://oauth.reddit.com/r/SUBREDDIT/about' \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "User-Agent: clawoop-bot/1.0"
```

### Search subreddits
```bash
curl -s 'https://oauth.reddit.com/subreddits/search?q=QUERY&limit=10' \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "User-Agent: clawoop-bot/1.0"
```

## Rules
- Always use `web_fetch` or `exec` with `curl` to make API calls.
- Always obtain a fresh access token at the start of a session — tokens expire in 1 hour.
- This integration is read-only — do not attempt to post, vote, or comment.
- The User-Agent header is required — Reddit blocks requests without it.
- When showing posts, display title, subreddit, score, and number of comments.
- Extract the post ID from the URL: `reddit.com/r/sub/comments/POST_ID/title/`
