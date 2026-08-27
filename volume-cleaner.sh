#!/bin/bash
# Volume Cleaner for Railway /data — keeps the small 434MB volume lean
# Run manually or via cron. Moves big expendable stuff to the big ephemeral overlay.

set -e
echo "=== Volume Cleaner $(date '+%Y-%m-%d %H:%M:%S') ==="

# 1. Clean pip cache (re-downloadable)
if [ -d /data/.cache/pip ]; then
  SIZE=$(du -sh /data/.cache/pip | cut -f1)
  rm -rf /data/.cache/pip
  echo "  - pip cache cleaned (was $SIZE)"
fi

# 2. Clean pub-cache if it appears (Flutter re-downloads it)
if [ -d /data/.pub-cache ]; then
  SIZE=$(du -sh /data/.pub-cache | cut -f1)
  rm -rf /data/.pub-cache
  echo "  - pub-cache cleaned (was $SIZE)"
fi

# 3. Clean old session request dumps (keep only newest 20)
if [ -d /data/.hermes/sessions ]; then
  OLD=$(ls -t /data/.hermes/sessions/request_dump_* 2>/dev/null | tail -n +21 | wc -l)
  if [ "$OLD" -gt 0 ]; then
    ls -t /data/.hermes/sessions/request_dump_* 2>/dev/null | tail -n +21 | xargs rm -f
    echo "  - removed $OLD old session dumps"
  fi
fi

# 4. Clean old logs (keep 5)
if [ -d /data/.hermes/logs ]; then
  for f in /data/.hermes/logs/*.log; do
    if [ -f "$f" ] && [ "$(stat -c%s "$f")" -gt 2000000 ]; then
      > "$f"
      echo "  - truncated large log $(basename "$f")"
    fi
  done
fi

echo "=== After cleanup: $(df -h /data | tail -1 | awk '{print $3" used, "$4" free"}') ==="