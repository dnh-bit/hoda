#!/bin/bash
# Disk Guard for Heda Project
# Stops anything that could fill the disk

MIN_GB=3
AVAIL_GB=$(df -BG / | tail -1 | awk '{print $4}' | tr -d 'G')
ALERT_GB=10
LOG="/data/workspace/heda/disk-guard.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Check: ${AVAIL_GB}GB free" >> "$LOG"

if [ "$AVAIL_GB" -lt "$MIN_GB" ]; then
  echo "⛔ CRITICAL: only ${AVAIL_GB}GB free (need ${MIN_GB}GB) — BLOCKED" | tee -a "$LOG"
  exit 1
elif [ "$AVAIL_GB" -lt "$ALERT_GB" ]; then
  echo "⚠️ WARNING: only ${AVAIL_GB}GB free — below ${ALERT_GB}GB alert threshold" | tee -a "$LOG"
  exit 0
else
  echo "✅ OK: ${AVAIL_GB}GB free" | tee -a "$LOG"
  exit 0
fi