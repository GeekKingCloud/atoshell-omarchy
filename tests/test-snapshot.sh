#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
project="$tmp/project with spaces"
mkdir -p "$project/.atoshell" "$tmp/bin"
printf '%s\n' '{"tickets":[]}' > "$project/.atoshell/queue.json"

cat > "$tmp/bin/atoshell" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
[[ -d .atoshell ]] || { printf 'wrong cwd\n' >&2; exit 70; }
case "$*" in
  'list in-progress --json')
    printf '%s\n' '[{"id":12,"title":"Ship queue panel","status":"In Progress","priority":"P1","size":"M","accountable":["agent-2"],"dependencies":[],"comments":[{"author":"agent-2","text":"Rendering active rows","created_at":"2026-08-14T20:00:00Z"}]}]'
    ;;
  'list ready --json')
    printf '%s\n' '[
      {"id":13,"title":"Ship API client","status":"Ready","priority":"P2","size":"S","accountable":[],"dependencies":[14],"comments":[]},
      {"id":14,"title":"Resolve dependency lock","status":"Ready","priority":"P3","size":"XS","accountable":[],"dependencies":[],"comments":[]}
    ]'
    ;;
  'list blockers --json')
    printf '%s\n' '[{"id":14,"title":"Resolve dependency lock","status":"Ready","priority":"P3","size":"XS","cycle":false,"blocking":[{"id":12,"title":"Ship queue panel"},{"id":13,"title":"Ship API client"}]}]'
    ;;
  *) printf 'unexpected argv: %s\n' "$*" >&2; exit 64 ;;
esac
FAKE
chmod +x "$tmp/bin/atoshell"

output=$(PATH="$tmp/bin:$PATH" "$repo_root/bin/atoshell-snapshot" "$project")
jq -e '
  .state == "ok" and
  .project.name == "project with spaces" and
  .counts.active == 1 and
  .counts.ready == 1 and
  .counts.blocked == 1 and
  (.active[0].id == 12) and
  (.active[0].latest_comment.text == "Rendering active rows") and
  (.active[0].blocked_by == [{id:14,title:"Resolve dependency lock"}]) and
  (.ready[0].id == 14) and
  (.blocked[0].id == 13) and
  (.blocked[0].blocked_by == [{id:14,title:"Resolve dependency lock"}])
' <<<"$output" >/dev/null

missing_output=$("$repo_root/bin/atoshell-snapshot" "$tmp/does-not-exist")
jq -e '.state == "missing-project" and (.message | contains("not found"))' <<<"$missing_output" >/dev/null

cat > "$tmp/bin/atoshell" <<'FAKE'
#!/usr/bin/env bash
printf '%s\n' '{"code":"BROKEN"}' >&2
exit 7
FAKE
chmod +x "$tmp/bin/atoshell"
failure_output=$(PATH="$tmp/bin:$PATH" "$repo_root/bin/atoshell-snapshot" "$project")
jq -e '.state == "atoshell-error" and (.message | contains("BROKEN"))' <<<"$failure_output" >/dev/null

cat > "$tmp/bin/atoshell" <<'FAKE'
#!/usr/bin/env bash
printf '%s\n' 'not-json'
FAKE
chmod +x "$tmp/bin/atoshell"
invalid_output=$(PATH="$tmp/bin:$PATH" "$repo_root/bin/atoshell-snapshot" "$project")
jq -e '.state == "invalid-data"' <<<"$invalid_output" >/dev/null

cat > "$tmp/bin/atoshell" <<'FAKE'
#!/usr/bin/env bash
sleep 5
FAKE
chmod +x "$tmp/bin/atoshell"
timeout_output=$(ATOSHELL_SNAPSHOT_TIMEOUT_SEC=1 PATH="$tmp/bin:$PATH" "$repo_root/bin/atoshell-snapshot" "$project")
jq -e '.state == "atoshell-timeout"' <<<"$timeout_output" >/dev/null

printf 'snapshot behavior: ok\n'
