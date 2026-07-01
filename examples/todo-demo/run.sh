#!/bin/bash
# Reproducible multi-agent demo: 3 opencode sessions on the cluster build a TODO app.
#   - 2 sentries register and park on wait_for_task (see ../sentry.md)
#   - 1 lead splits the app into 3 file-scoped tasks and delegates them
# The sentries claim (atomically), go to the task's path, and write real files.
#
# This script only exists to run the demo UNATTENDED. In a real session you don't
# need it: open two opencode windows, paste ../sentry.md into each, then tell a
# third to "build a TODO app, split it into files, delegate each via the cluster."
#
# Prereqs: cluster up (docker compose up -d), opencode logged into the model.
#   bash run.sh
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/app"; LOGS="$DIR/logs"; rm -rf "$APP" "$LOGS"; mkdir -p "$APP" "$LOGS"
export OPENCODE_CONFIG="$DIR/../opencode.jsonc"
CL="${CLUSTER_URL:-http://localhost:8080}"; MODEL="${WORKER_MODEL:-minimax-coding-plan/MiniMax-M3}"
count() { curl -s "$CL/tasks?status=$1" | python -c "import sys,json;print(len(json.load(sys.stdin)['items']))" 2>/dev/null || echo 0; }

sentry() {
  local name=$1 id=$2
  local prompt="You are a cluster sentry '$name' (worker_id='$id'), skills: coding. Using the cluster MCP tools:
register_worker(name='$name', skills=['coding'], worker_id='$id').
wait_for_task(skills=['coding'], timeout=100). If it returns {task:null}, stop.
claim_task(task_id,'$id'); if claimed is false, stop.
get_task(task_id); build EXACTLY the one file it asks for in your current directory with your write tool, matching the filename and integration contract precisely.
send_message(sender='$id', content='<one line>', task_id=task_id, conversation_id=<the task conversation_id>).
complete_task(task_id, result='<summary>').
Actually write the file. Do only the one task you claimed, then finish."
  for i in 1 2 3 4; do
    echo "[$name] iteration $i (waiting for work)"
    ( cd "$APP" && opencode run -m "$MODEL" --dangerously-skip-permissions "$prompt" > "$LOGS/$name-$i.log" 2>&1 )
    [ "$(count open)" = "0" ] && [ "$(count assigned)" = "0" ] && break
  done
  echo "[$name] stopped"
}

echo "== launching 2 sentries =="
sentry SentryA wkr-a & sentry SentryB wkr-b &
until curl -s "$CL/workers" | python -c "import sys,json;i=[w['id'] for w in json.load(sys.stdin)['items']];import sys;sys.exit(0 if 'wkr-a' in i and 'wkr-b' in i else 1)"; do sleep 3; done
echo "== sentries parked; launching lead to delegate =="

LEAD="You are the lead engineer. Build a small browser TODO app in the folder: $APP
Split it into EXACTLY 3 independent files so parallel workers never touch the same file:
 - index.html: a text input (id='todo-input'), Add button (id='add-btn'), empty <ul id='todo-list'>, linking styles.css and app.js (defer).
 - app.js: add on click and Enter, each item has text + delete button + click-to-toggle a 'done' class, persist to localStorage and reload on start.
 - styles.css: clean centered card, and a .done style with line-through + muted color.
For EACH file call create_task(title, description, required_skill='coding', path='$APP'), with the description stating the exact filename and everything above so a worker seeing only that task builds it correctly and it integrates. Create all 3. Write no code yourself. Then stop."
( cd "$APP" && opencode run -m "$MODEL" --dangerously-skip-permissions "$LEAD" > "$LOGS/lead.log" 2>&1 )
echo "== lead delegated; waiting for 3 components =="
for _ in $(seq 1 72); do c=$(count completed); echo "completed=$c/3"; [ "$c" -ge 3 ] && break; sleep 5; done
wait
echo "== done. app files: =="; ls -la "$APP"
