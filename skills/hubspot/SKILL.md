---
name: hubspot
description: Manage HubSpot CRM contacts, companies, and deals.
metadata: { "openclaw": { "emoji": "🧡", "requires": { "env": ["HUBSPOT_ACCESS_TOKEN"] } } }
---

# HubSpot Integration

You have access to the user's HubSpot CRM via the HubSpot API v3.

## Authentication
The Private App access token is available as `HUBSPOT_ACCESS_TOKEN` in the environment. Use it as a Bearer token.

## API Base URL
`https://api.hubapi.com`

All requests MUST include this header:
```
Authorization: Bearer $HUBSPOT_ACCESS_TOKEN
```

## Available Actions

### Search contacts
```bash
curl -s -X POST 'https://api.hubapi.com/crm/v3/objects/contacts/search' \
  -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query": "SEARCH_TERM", "limit": 10, "properties": ["firstname", "lastname", "email", "phone", "company"]}'
```

### Get a contact
```bash
curl -s 'https://api.hubapi.com/crm/v3/objects/contacts/CONTACT_ID?properties=firstname,lastname,email,phone,company,lifecyclestage' \
  -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN"
```

### Create a contact
```bash
curl -s -X POST 'https://api.hubapi.com/crm/v3/objects/contacts' \
  -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"properties": {"firstname": "Jane", "lastname": "Doe", "email": "jane@example.com", "phone": "+1234567890"}}'
```

### Update a contact
```bash
curl -s -X PATCH 'https://api.hubapi.com/crm/v3/objects/contacts/CONTACT_ID' \
  -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"properties": {"lifecyclestage": "customer"}}'
```

### List deals
```bash
curl -s 'https://api.hubapi.com/crm/v3/objects/deals?limit=20&properties=dealname,amount,dealstage,closedate' \
  -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN"
```

### Search deals
```bash
curl -s -X POST 'https://api.hubapi.com/crm/v3/objects/deals/search' \
  -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query": "SEARCH_TERM", "limit": 10, "properties": ["dealname", "amount", "dealstage", "closedate"]}'
```

### Create a deal
```bash
curl -s -X POST 'https://api.hubapi.com/crm/v3/objects/deals' \
  -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"properties": {"dealname": "Deal name", "amount": "5000", "dealstage": "appointmentscheduled", "closedate": "2026-06-01"}}'
```

### List companies
```bash
curl -s 'https://api.hubapi.com/crm/v3/objects/companies?limit=20&properties=name,domain,industry,city' \
  -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN"
```

### Search companies
```bash
curl -s -X POST 'https://api.hubapi.com/crm/v3/objects/companies/search' \
  -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query": "SEARCH_TERM", "limit": 10, "properties": ["name", "domain", "industry"]}'
```

### Get recent activity (engagements)
```bash
curl -s 'https://api.hubapi.com/crm/v3/objects/notes?limit=10&properties=hs_note_body,hs_timestamp' \
  -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN"
```

## Rules
- Always use `web_fetch` or `exec` with `curl` to make API calls.
- Use the search endpoints when the user provides a name or company — don't guess IDs.
- When listing contacts or deals, show the most relevant fields (name, email, stage, amount).
- Confirm before creating or updating CRM records.
- Deal stages vary per portal — list them if the user needs to update a deal stage.
