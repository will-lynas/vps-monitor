#!/usr/bin/env bash

set -e

CHAT_ID=$1
BOT_TOKEN=$2

INTERFACE=ens1

RAM_AWK_SCRIPT='
BEGIN {
    printf "%-6s %-6s %-6s\n", "Total", "Used", "Used%"
}
/Average/ {
    printf "%-6.2f %-6.2f %-6.2f\n", $3/1024/1024, $4/1024/1024, $5
}'

CPU_AWK_SCRIPT='
BEGIN {
    printf "%-7s %-8s %-7s\n", "User%", "System%", "Idle%"
}
/Average/ {
    printf "%-7.2f %-8.2f %-7.2f\n", $3, $5, $8
}'

NETWORK_AWK_SCRIPT='
/Average/ && $2 == "'"$INTERFACE"'" {
    rx_mb = $5 * 3600 / 1024
    tx_mb = $6 * 3600 / 1024
    printf "RX: %.4f\nTX: %.4f\n", rx_mb, tx_mb
}'

END_TIME=$(date +%H:%M:%S)
START_TIME=$(date --date='1 hour ago' +%H:%M:%S)

CPU_USAGE=$(sar -u -s "$START_TIME" -e "$END_TIME" | awk "$CPU_AWK_SCRIPT")
RAM_USAGE=$(sar -r -s "$START_TIME" -e "$END_TIME" | awk "$RAM_AWK_SCRIPT")
NETWORK_USAGE=$(sar -n DEV -s "$START_TIME" -e "$END_TIME" | awk "$NETWORK_AWK_SCRIPT")

MESSAGE=$(cat <<EOF
*System Monitoring Report: Last Hour*

*CPU Usage:*
\`\`\`
$(echo "$CPU_USAGE")
\`\`\`

*RAM Usage (GB):*
\`\`\`
$(echo "$RAM_USAGE")
\`\`\`

*Network Usage (MB/h):*
\`\`\` 
$(echo "$NETWORK_USAGE")
\`\`\`
EOF
)

curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
     -d chat_id="$CHAT_ID" \
     -d text="$MESSAGE" \
     -d parse_mode="Markdown" | jq
