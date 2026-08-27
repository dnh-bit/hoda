#!/bin/bash
# Volume Guard for Railway /data volume (434MB small volume)
# Monitors the REAL volume (not overlay /) — sends warnings before it fills

VOLUME="/data"
WARN_PCT=70
CRIT_PCT=90
LOG="/data/workspace/heda/volume-guard.log"

# Get usage percentage of the actual volume mount
USED_PCT=$(df -h "$VOLUME" | tail -1 | awk '{print $5}' | tr -d '%')
AVAIL_GB=$(df -h "$VOLUME" | tail -1 | awk '{print $4}')

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Volume: ${USED_PCT}% used (${AVAIL_GB} available)" >> "$LOG"

if [ "$USED_PCT" -ge "$CRIT_PCT" ]; then
  echo "⛔ CRITICAL: volume ${USED_PCT}% full (only ${AVAIL_GB} left) — FREE SPACE NOW!" | tee -a "$LOG"
  echo "   Largest dirs: $(du -h -d 1 "$VOLUME" 2>/dev/null | sort -rh | head -5 | tr '\n' ' ')" | tee -a "$LOG"
  exit 1
elif [ "$USED_PCT" -ge "$WARN_PCT" ]; then
  echo "⚠️ WARNING: volume ${USED_PCT}% full (${AVAIL_GB} available) — plan to clean" | tee -a "$LOG"
  exit 0
else
  echo "✅ OK: volume ${USED_PCT}% used (${AVAIL_GB} available)" | tee -a "$LOG"
  exit 0
fi