#!/bin/bash
# watch_live_launch.sh — Monitor for Ableton Live launch and start LES
#
# This script is managed by the "launchwithlive" setting.
# It polls for the Ableton Live process and launches LES when detected.
# Once LES is running alongside Live, it idles until Live quits,
# then resumes watching for the next launch.

set -euo pipefail

LIVE_PROCESS_NAME="Live"
LES_BUNDLE_ID="org.les.Live-Enhancement-Suite-Custom"
POLL_INTERVAL=3

is_live_running() {
    pgrep -xq "$LIVE_PROCESS_NAME"
}

is_les_running() {
    pgrep -f "$LES_BUNDLE_ID" >/dev/null 2>&1 || \
        pgrep -f "Live Enhancement Suite Custom" >/dev/null 2>&1
}

while true; do
    if is_live_running; then
        if ! is_les_running; then
            open -b "$LES_BUNDLE_ID" 2>/dev/null || \
                open -a "Live Enhancement Suite Custom" 2>/dev/null || true
        fi
        # Wait until Live quits before resuming the watch loop
        while is_live_running; do
            sleep "$POLL_INTERVAL"
        done
    fi
    sleep "$POLL_INTERVAL"
done
