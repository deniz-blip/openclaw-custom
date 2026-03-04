---
name: todoist
description: Manage tasks, projects, and reminders in Todoist.
metadata: { "openclaw": { "emoji": "✅", "requires": { "env": ["TODOIST_API_TOKEN"] } } }
---

# Todoist Integration

You have access to the user's Todoist account via the Todoist REST API v2.

## Authentication
The API token is available as `TODOIST_API_TOKEN` in the environment. Use it as a Bearer token.

## API Base URL
`https://api.todoist.com/rest/v2`

All requests MUST include this header:
```
Authorization: Bearer $TODOIST_API_TOKEN
```

## Available Actions

### Get all active tasks
```bash
curl -s 'https://api.todoist.com/rest/v2/tasks' \
  -H "Authorization: Bearer $TODOIST_API_TOKEN"
```

### Get tasks for a project
```bash
curl -s 'https://api.todoist.com/rest/v2/tasks?project_id=PROJECT_ID' \
  -H "Authorization: Bearer $TODOIST_API_TOKEN"
```

### Get tasks due today
```bash
curl -s 'https://api.todoist.com/rest/v2/tasks?filter=today' \
  -H "Authorization: Bearer $TODOIST_API_TOKEN"
```

### Create a task
```bash
curl -s -X POST 'https://api.todoist.com/rest/v2/tasks' \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content": "Task title", "due_string": "tomorrow", "priority": 2}'
```
Priority: 1=Normal, 2=Medium, 3=High, 4=Urgent.

### Complete a task
```bash
curl -s -X POST 'https://api.todoist.com/rest/v2/tasks/TASK_ID/close' \
  -H "Authorization: Bearer $TODOIST_API_TOKEN"
```

### Update a task
```bash
curl -s -X POST 'https://api.todoist.com/rest/v2/tasks/TASK_ID' \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content": "Updated title", "due_string": "next monday"}'
```

### Delete a task
```bash
curl -s -X DELETE 'https://api.todoist.com/rest/v2/tasks/TASK_ID' \
  -H "Authorization: Bearer $TODOIST_API_TOKEN"
```

### List all projects
```bash
curl -s 'https://api.todoist.com/rest/v2/projects' \
  -H "Authorization: Bearer $TODOIST_API_TOKEN"
```

### Create a project
```bash
curl -s -X POST 'https://api.todoist.com/rest/v2/projects' \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Project name"}'
```

### Get comments on a task
```bash
curl -s 'https://api.todoist.com/rest/v2/comments?task_id=TASK_ID' \
  -H "Authorization: Bearer $TODOIST_API_TOKEN"
```

### Add a comment to a task
```bash
curl -s -X POST 'https://api.todoist.com/rest/v2/comments' \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"task_id": "TASK_ID", "content": "Comment text"}'
```

## Rules
- Always use `web_fetch` or `exec` with `curl` to make API calls.
- When listing tasks, show content, due date, and priority.
- Natural language due strings (e.g. "tomorrow", "next monday", "every day") are supported.
- Confirm before deleting tasks or projects.
- When the user says "done" or "complete", use the close endpoint.
