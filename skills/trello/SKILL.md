---
name: trello
description: Manage boards, lists, and cards on Trello.
metadata: { "openclaw": { "emoji": "📋", "requires": { "env": ["TRELLO_API_KEY", "TRELLO_TOKEN"] } } }
---

# Trello Integration

You have access to the user's Trello workspace via the Trello REST API.

## Authentication
API key and token are available as `TRELLO_API_KEY` and `TRELLO_TOKEN`. Append them as query parameters to every request.

## API Base URL
`https://api.trello.com/1`

## Available Actions

### List user's boards
```bash
curl -s 'https://api.trello.com/1/members/me/boards?key='$TRELLO_API_KEY'&token='$TRELLO_TOKEN'&fields=name,url,dateLastActivity'
```

### Get a board
```bash
curl -s 'https://api.trello.com/1/boards/BOARD_ID?key='$TRELLO_API_KEY'&token='$TRELLO_TOKEN'&fields=name,desc,url'
```

### List board's lists
```bash
curl -s 'https://api.trello.com/1/boards/BOARD_ID/lists?key='$TRELLO_API_KEY'&token='$TRELLO_TOKEN'&fields=name,pos'
```

### List cards in a list
```bash
curl -s 'https://api.trello.com/1/lists/LIST_ID/cards?key='$TRELLO_API_KEY'&token='$TRELLO_TOKEN'&fields=name,desc,due,labels'
```

### Create a card
```bash
curl -s -X POST 'https://api.trello.com/1/cards?key='$TRELLO_API_KEY'&token='$TRELLO_TOKEN \
  -H "Content-Type: application/json" \
  -d '{"idList": "LIST_ID", "name": "Card Title", "desc": "Description"}'
```

### Move a card to another list
```bash
curl -s -X PUT 'https://api.trello.com/1/cards/CARD_ID?key='$TRELLO_API_KEY'&token='$TRELLO_TOKEN \
  -H "Content-Type: application/json" \
  -d '{"idList": "TARGET_LIST_ID"}'
```

### Add a comment to a card
```bash
curl -s -X POST 'https://api.trello.com/1/cards/CARD_ID/actions/comments?key='$TRELLO_API_KEY'&token='$TRELLO_TOKEN \
  -H "Content-Type: application/json" \
  -d '{"text": "Comment text"}'
```

### Search cards
```bash
curl -s 'https://api.trello.com/1/search?query=SEARCH_TERM&key='$TRELLO_API_KEY'&token='$TRELLO_TOKEN'&modelTypes=cards'
```

## Rules
- Always use `web_fetch` or `exec` with `curl` to make API calls.
- When listing boards/cards, present them clearly with names and relevant details.
- Confirm before creating, moving, or deleting cards.
- Show board name and list name when displaying card information.
