---
name: airtable
description: Read, create, update, and delete records in Airtable bases and tables.
metadata: { "openclaw": { "emoji": "📊", "requires": { "env": ["AIRTABLE_PAT"] } } }
---

# Airtable Integration

You have access to the user's Airtable workspace via the Airtable REST API.

## Authentication
The Personal Access Token is available as `AIRTABLE_PAT` in the environment. Use it as a Bearer token.

## API Base URL
`https://api.airtable.com/v0`

All requests MUST include this header:
```
Authorization: Bearer $AIRTABLE_PAT
```

## Available Actions

### List all bases
```bash
curl -s 'https://api.airtable.com/v0/meta/bases' \
  -H "Authorization: Bearer $AIRTABLE_PAT"
```

### List tables in a base
```bash
curl -s 'https://api.airtable.com/v0/meta/bases/BASE_ID/tables' \
  -H "Authorization: Bearer $AIRTABLE_PAT"
```

### List records in a table
```bash
curl -s 'https://api.airtable.com/v0/BASE_ID/TABLE_NAME?maxRecords=20' \
  -H "Authorization: Bearer $AIRTABLE_PAT"
```

### Filter records
```bash
curl -s 'https://api.airtable.com/v0/BASE_ID/TABLE_NAME?filterByFormula=FILTER_FORMULA&maxRecords=20' \
  -H "Authorization: Bearer $AIRTABLE_PAT"
```
Example filter: `filterByFormula=%7BStatus%7D%3D%22Done%22` (URL-encoded `{Status}="Done"`)

### Search records (filter by field)
```bash
curl -s 'https://api.airtable.com/v0/BASE_ID/TABLE_NAME?filterByFormula=SEARCH%28%22SEARCH_TERM%22%2CNAME_FIELD%29' \
  -H "Authorization: Bearer $AIRTABLE_PAT"
```

### Get a single record
```bash
curl -s 'https://api.airtable.com/v0/BASE_ID/TABLE_NAME/RECORD_ID' \
  -H "Authorization: Bearer $AIRTABLE_PAT"
```

### Create a record
```bash
curl -s -X POST 'https://api.airtable.com/v0/BASE_ID/TABLE_NAME' \
  -H "Authorization: Bearer $AIRTABLE_PAT" \
  -H "Content-Type: application/json" \
  -d '{"fields": {"Name": "Record name", "Status": "Todo"}}'
```

### Update a record
```bash
curl -s -X PATCH 'https://api.airtable.com/v0/BASE_ID/TABLE_NAME/RECORD_ID' \
  -H "Authorization: Bearer $AIRTABLE_PAT" \
  -H "Content-Type: application/json" \
  -d '{"fields": {"Status": "Done"}}'
```

### Delete a record
```bash
curl -s -X DELETE 'https://api.airtable.com/v0/BASE_ID/TABLE_NAME/RECORD_ID' \
  -H "Authorization: Bearer $AIRTABLE_PAT"
```

## Rules
- Always use `web_fetch` or `exec` with `curl` to make API calls.
- Base IDs start with `app`, record IDs start with `rec`.
- TABLE_NAME can be the table name (URL-encoded) or table ID (starts with `tbl`).
- Always list bases first if the user hasn't specified one.
- Confirm before deleting records.
- Handle pagination using the `offset` param returned in responses.
