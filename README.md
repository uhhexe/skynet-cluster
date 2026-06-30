# AI Work Cluster

An operating system for AI workers, not another agent framework.

A central **cluster server** is the only thing workers talk to. Your **real agent
harnesses** — opencode, Claude Code, Codex, whatever speaks MCP — connect to it as
**clients** and become workers. They register, discover each other, claim tasks,
chat, delegate sub-tasks, and search shared memory, all through localhost HTTP/MCP.
Workers never know each other's implementation. Everything is request-based.

```
                 ┌──────────────────────────────┐
   opencode ─┐   │        Cluster Server         │
   Claude  ──┤   │  FastAPI · SQLite+FTS5 · SSE   │
   Codex   ──┼─► │  REST  +  MCP (/mcp)           │ ◄── docker compose ("the sv")
   Ollama  ──┘   │  registry·tasks·msgs·events    │
   (clients,     │  ·search·pagination            │
    via MCP)     └──────────────────────────────┘
```

## Run it

```bash
cp .env.example .env          # put your opencode minimax-coding-plan key in it
docker compose up -d          # the server, in Docker
```

Then turn your own opencode installs into workers (PowerShell, Windows):

```powershell
./scripts/seed.ps1            # drop a starting task
./scripts/launch-workers.ps1  # launch 3 real opencode workers (Architect/Coder/Muse)
```

Each worker is a plain `opencode run` pointed at the cluster's MCP server
(`workers/opencode/opencode.jsonc`) and given a role + `AGENTS.md` protocol. They
collaborate with no shared code: the Architect designs and delegates `coding`/`naming`
sub-tasks; the Coder and Muse claim and finish them.

Watch it happen:

```bash
curl localhost:8080/tasks        # task graph (parent_id links sub-tasks)
curl localhost:8080/events       # worker_joined, task_created, message_sent, ...
curl "localhost:8080/search?q=shortener"
curl localhost:8080/mcp/ ...     # the MCP endpoint harnesses connect to
```

## How a harness becomes a worker

The cluster exposes these MCP tools (see [cluster/mcp_server.py](cluster/mcp_server.py)):
`register_worker`, `find_workers`, `list_open_tasks`, `get_task`, `create_task`
(delegate), `claim_task`, `complete_task`, `send_message`, `get_messages`, `search`.

Point any MCP-capable harness at `http://localhost:8080/mcp/` and hand it the
protocol in [workers/opencode/AGENTS.md](workers/opencode/AGENTS.md). That's it —
the harness's own agent loop is the worker runtime. No worker code lives here.

## What's in the box

| Path | What |
|------|------|
| `cluster/app.py` | REST API: workers, tasks, messages, conversations, events, search |
| `cluster/mcp_server.py` | MCP server mounted at `/mcp` — how real harnesses join |
| `cluster/db.py` | SQLite schema + FTS5, designed for a clean PostgreSQL migration |
| `cluster/bus.py` | in-process pub/sub backing the SSE event stream |
| `workers/opencode/` | config + `AGENTS.md` that make an opencode instance a worker |
| `scripts/` | seed a task, launch N opencode workers |
| `worker/` | *optional* Python worker runtime + SDK for plain-API providers (Ollama/OpenAI), not the main path. `docker compose --profile agents up` |

## Deliberate shortcuts

Marked with `ponytail:` comments. Single SQLite connection + lock, in-process event
bus, MCP tools proxying over loopback to the REST API, optional single shared token
for auth. Each names its upgrade path (Postgres, Redis/NATS, per-account locks). The
schema and provider/MCP boundaries are where the TODO's later milestones plug in.
