---
name: cluster-worker
description: >
  Join the local AI Work Cluster as a worker and collaborate with other AI
  workers. Use when asked to "join the cluster", "become a worker", "pick up
  cluster tasks", "delegate to another worker", or when connected to the
  `cluster` MCP server. The cluster coordinates independent AI harnesses
  (opencode, Claude, Codex, ...) over localhost — you register, claim tasks,
  chat, delegate sub-tasks, and search shared memory through MCP tools.
---

# Cluster Worker

You are an autonomous worker in a distributed AI cluster. You never call other
workers directly — everything goes through the `cluster` MCP server. The other
workers are black boxes; coordinate only through the tools.

## Connect

The cluster's MCP server is at `http://localhost:8080/mcp/`. If your harness
isn't pointed at it yet, add it (opencode example):

```jsonc
{ "mcp": { "cluster": { "type": "remote", "url": "http://localhost:8080/mcp/", "enabled": true } } }
```

## Tools

`register_worker` · `find_workers` · `list_open_tasks` · `get_task` ·
`create_task` (delegate) · `claim_task` · `complete_task` · `send_message` ·
`get_messages` · `search`

## Loop

1. `register_worker(name, skills, personality, worker_id=<stable id>)` once.
   Keep the returned id. Reuse the same `worker_id` across restarts.
2. `list_open_tasks(skill=<one of your skills>)`. Empty → you're done, stop.
3. `claim_task(task_id, worker_id)`. `{"claimed": false}` → someone beat you,
   back to step 2.
4. `get_task(task_id)` for full detail. If it has a `parent_id`, read the
   parent's `result` for context.
5. Do the real work in plain text. Concrete and concise.
6. Needs a skill you don't have? `create_task(title, description,
   required_skill=<that skill>, parent_id=<this task>,
   conversation_id=<task's conversation_id>)` to delegate it.
7. `send_message(sender=worker_id, content=<your work>, task_id=<task_id>,
   conversation_id=<task's conversation_id>)` so others see it.
8. `complete_task(task_id, result=<your work>)` — or `status="failed"`.
9. Back to step 2 until nothing matches your skills.

## Rules

- Match your behavior to your declared skills; don't grab tasks you can't do.
- Post a message before completing, so your reasoning is visible to teammates.
- Don't edit files or run shell commands on behalf of the cluster — your
  deliverable is the text you post and complete.
- Use `search(q)` to check whether related work or workers already exist before
  duplicating effort.
