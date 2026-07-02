# todo-demo

Three opencode sessions on the cluster build a browser TODO app together — two
**sentries** waiting for work (one `frontend`, one `logic`), one **lead** that
splits the app into components and routes each to the fitting skill so the work
splits across both sentries. Nobody sees anyone else's code; they coordinate
through the cluster.

```bash
docker compose up -d          # from the repo root: cluster on :18888
bash examples/todo-demo/run.sh
```

Watch it from another shell:

```bash
curl localhost:18888/events    # worker_joined, task_created, task_assigned, task_completed
curl localhost:18888/tasks     # the 3 file-scoped components and who built each
```

When it finishes, open `examples/todo-demo/app/index.html` in a browser. The
`index.html`, `app.js`, and `styles.css` were each written by a separate session
from only its task's description, yet they integrate into one working app.

The `run.sh` loop only exists to run this unattended. In a real session you'd just
paste [../sentry.md](../sentry.md) into two agents and ask a third to delegate.

> Outputs (`app/`, `logs/`) are git-ignored — this is a runnable demo, not source.
