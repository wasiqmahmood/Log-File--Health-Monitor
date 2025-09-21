#!/bin/bash

# Validate input
[ $# -ne 1 ] || [ ! -f "$1" ] && echo "Usage: $0 /path/to/logfile" && exit 1

LOG_FILE="$1"
REPORT_FILE="log_analysis_$(date +%Y%m%d_%H%M%S).txt"

# Count messages
count_messages() {
    grep -ic "$1" "$LOG_FILE" | awk '{printf "%'"'"'d", $1}'
}

ERROR_COUNT=$(count_messages "ERROR")
WARNING_COUNT=$(count_messages "WARNING")
INFO_COUNT=$(count_messages "INFO")

# Extract top errors
TOP_ERRORS=$(grep -i "ERROR" "$LOG_FILE" | \
    sed 's/.*ERROR: //i; s/.*ERROR //i; s/^.*kernel: //' | \
    sort | uniq -c | sort -nr | head -5 | \
    awk '{printf "%3d - %s\n", $1, substr($0, index($0,$2))}')

# Get first and last error timestamps
get_timestamp() {
    grep -i "ERROR" "$LOG_FILE" | $1 -1 | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}' | head -1
}
FIRST_ERROR=$(get_timestamp head)
LAST_ERROR=$(get_timestamp tail)

# Count errors by hour
declare -a HOUR_BUCKETS=(0 0 0 0 0 0)
while IFS= read -r line; do
    HOUR=$(echo "$line" | grep -oE 'T[0-9]{2}:' | cut -d: -f1 | tr -d 'T' | sed 's/^0//')
    [ -n "$HOUR" ] && index=$((HOUR/4)) && [ $index -lt 6 ] && ((HOUR_BUCKETS[index]++))
done < <(grep -i "ERROR" "$LOG_FILE")

# Draw bar function
draw_bar() {
    [ $1 -eq 0 ] && echo "" && return
    printf '█%.0s' $(seq 1 $((1 + ($1 * 8 / (${HOUR_BUCKETS[2]} + 1)))))
}

# Generate report
{
echo "===== LOG FILE ANALYSIS REPORT ====="
echo "File: $LOG_FILE"
echo "Analyzed on: $(date)"
echo "Size: $(du -h "$LOG_FILE" | cut -f1) ($(wc -c < "$LOG_FILE" | awk '{printf "%'"'"'d", $1}') bytes)"
echo
echo "MESSAGE COUNTS:"
echo "ERROR: $ERROR_COUNT"
echo "WARNING: $WARNING_COUNT"
echo "INFO: $INFO_COUNT"
echo
echo "TOP 5 ERROR MESSAGES:"
echo "${TOP_ERRORS:-No ERROR messages found}"
echo
echo "ERROR TIMELINE:"
[ -n "$FIRST_ERROR" ] && echo "First error: $FIRST_ERROR" && echo "Last error:  $LAST_ERROR" || echo "No ERROR messages found"
echo
echo "Error frequency by hour:"
[ $ERROR_COUNT -gt 0 ] && \
    echo "00-04: $(draw_bar ${HOUR_BUCKETS[0]}) (${HOUR_BUCKETS[0]})" && \
    echo "04-08: $(draw_bar ${HOUR_BUCKETS[1]}) (${HOUR_BUCKETS[1]})" && \
    echo "08-12: $(draw_bar ${HOUR_BUCKETS[2]}) (${HOUR_BUCKETS[2]})" && \
    echo "12-16: $(draw_bar ${HOUR_BUCKETS[3]}) (${HOUR_BUCKETS[3]})" && \
    echo "16-20: $(draw_bar ${HOUR_BUCKETS[4]}) (${HOUR_BUCKETS[4]})" && \
    echo "20-24: $(draw_bar ${HOUR_BUCKETS[5]}) (${HOUR_BUCKETS[5]})" || \
    echo "No ERROR messages to analyze"
} | tee "$REPORT_FILE"

echo "Report saved to: $REPORT_FILE"
