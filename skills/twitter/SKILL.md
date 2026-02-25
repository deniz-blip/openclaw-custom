---
name: twitter
description: Post tweets, search content, and manage timeline on Twitter/X.
metadata: { "openclaw": { "emoji": "🐦", "requires": { "env": ["X_API_KEY", "X_API_SECRET", "X_ACCESS_TOKEN", "X_ACCESS_SECRET"] } } }
---

# Twitter/X Integration

You have access to the user's Twitter/X account via the X API v2.

## Authentication
OAuth 1.0a credentials are available as environment variables:
- `X_API_KEY` (consumer key)
- `X_API_SECRET` (consumer secret)
- `X_ACCESS_TOKEN` (access token)
- `X_ACCESS_SECRET` (access token secret)

Since OAuth 1.0a signing is complex, use a helper approach with `exec`:

### OAuth 1.0a signing helper
For each request, generate the OAuth signature. The simplest way is to use `curl` with a pre-built OAuth header, or use Python's `requests_oauthlib`:

```bash
python3 -c "
import os, json
from requests_oauthlib import OAuth1Session

oauth = OAuth1Session(
    os.environ['X_API_KEY'],
    client_secret=os.environ['X_API_SECRET'],
    resource_owner_key=os.environ['X_ACCESS_TOKEN'],
    resource_owner_secret=os.environ['X_ACCESS_SECRET']
)

# Replace with actual request:
r = oauth.get('https://api.twitter.com/2/users/me')
print(json.dumps(r.json(), indent=2))
"
```

## API Base URL
`https://api.twitter.com/2`

## Available Actions

### Get authenticated user info
```python
r = oauth.get('https://api.twitter.com/2/users/me?user.fields=name,username,description,public_metrics')
```

### Post a tweet
```python
r = oauth.post('https://api.twitter.com/2/tweets', json={"text": "Tweet content"})
```

### Search recent tweets
```python
r = oauth.get('https://api.twitter.com/2/tweets/search/recent?query=SEARCH_QUERY&max_results=10&tweet.fields=created_at,author_id,text')
```

### Get user's timeline
```python
r = oauth.get('https://api.twitter.com/2/users/USER_ID/tweets?max_results=10&tweet.fields=created_at,text,public_metrics')
```

### Like a tweet
```python
r = oauth.post('https://api.twitter.com/2/users/USER_ID/likes', json={"tweet_id": "TWEET_ID"})
```

### Reply to a tweet
```python
r = oauth.post('https://api.twitter.com/2/tweets', json={"text": "Reply text", "reply": {"in_reply_to_tweet_id": "TWEET_ID"}})
```

## Rules
- Always use Python with `requests_oauthlib` for OAuth 1.0a signing.
- **Always confirm before posting tweets** — this is a public action.
- When searching, present results with author, text, and engagement metrics.
- Respect rate limits (300 tweets/3hrs for posting).
- If `requests_oauthlib` is not available, install it: `pip install requests-oauthlib`.
