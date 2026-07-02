<#
Run the cluster WITHOUT Docker.

It's a single Python process (~30 MB RAM, SQLite file on disk) — on Windows this
avoids Docker Desktop's WSL2 VM, which reserves ~2 GB of system memory no matter
how small the container is. Use this for day-to-day; use `docker compose up` only
if you specifically want it isolated in a container.

  ./scripts/run-cluster.ps1            # http://localhost:18888  (Ctrl+C to stop)
#>
param([int]$Port = 18888)
$Root = (Join-Path $PSScriptRoot ".." | Resolve-Path).Path
python -m pip install -q -r (Join-Path $Root "cluster/requirements.txt")
# tell the in-process MCP proxy which port it lives on (it calls its own REST API)
$env:SELF_URL = "http://127.0.0.1:$Port"
Push-Location $Root
try { python -m uvicorn cluster.app:app --host 0.0.0.0 --port $Port }
finally { Pop-Location }
