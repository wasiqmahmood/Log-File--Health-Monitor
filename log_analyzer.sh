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

# Extract top errors - FIXED: handles space after ERROR
TOP_ERRORS=$(grep -i "ERROR" "$LOG_FILE" | \
    sed 's/.*ERROR: //i; s/.*ERROR //i; s/^[0-9:-]* *//' | \
    sort | uniq -c | sort -nr | head -5 | \
    awk '{printf "%3d - %s\n", $1, substr($0, index($0,$2))}')

# Get first and last error timestamps - FIXED: shows full line
get_timestamp() {
    grep -i "ERROR" "$LOG_FILE" | $1 -1
}
FIRST_ERROR=$(get_timestamp head)
LAST_ERROR=$(get_timestamp tail)

# Count errors by hour - FIXED: correct timestamp parsing
declare -a HOUR_BUCKETS=(0 0 0 0 0 0)
while IFS= read -r line; do
    # Extract hour from format: "2025-10-05 08:12:03"
    HOUR=$(echo "$line" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}' | cut -d' ' -f2 | cut -d: -f1 | sed 's/^0//')
    if [ -n "$HOUR" ]; then
        # Calculate bucket index (0-5 for 4-hour intervals)
        index=$((HOUR/4))
        [ $index -lt 6 ] && ((HOUR_BUCKETS[index]++))
    fi
done < <(grep -i "ERROR" "$LOG_FILE")

# Draw bar function - FIXED: better scaling
draw_bar() {
    local count=$1
    [ $count -eq 0 ] && echo "" && return
    
    # Find max count for scaling
    local max_count=0
    for bucket in "${HOUR_BUCKETS[@]}"; do
        [ $bucket -gt $max_count ] && max_count=$bucket
    done
    
    [ $max_count -eq 0 ] && echo "" && return
    
    # Scale bar length (max 12 chars)
    local bar_len=$((count * 12 / max_count))
    [ $bar_len -lt 1 ] && [ $count -gt 0 ] && bar_len=1
    printf '█%.0s' $(seq 1 $bar_len)
}

# Generate report
{
echo "===== LOG FILE ANALYSIS REPORT ====="
echo "File: $LOG_FILE"
echo "Analyzed on: $(date)"
echo "Size: $(du -h "$LOG_FILE" 2>/dev/null | cut -f1) ($(wc -c < "$LOG_FILE" 2>/dev/null | awk '{printf "%'"'"'d", $1}') bytes)"
echo
echo "MESSAGE COUNTS:"
echo "ERROR: $ERROR_COUNT messages"
echo "WARNING: $WARNING_COUNT messages"
echo "INFO: $INFO_COUNT messages"
echo
echo "TOP 5 ERROR MESSAGES:"
if [ -n "$TOP_ERRORS" ] && [ "$ERROR_COUNT" -gt 0 ]; then
    echo "$TOP_ERRORS"
else
    echo "No ERROR messages found"
fi
echo
echo "ERROR TIMELINE:"
if [ -n "$FIRST_ERROR" ] && [ "$ERROR_COUNT" -gt 0 ]; then
    echo "First error: $FIRST_ERROR"
    echo "Last error:  $LAST_ERROR"
else
    echo "No ERROR messages found"
fi
echo
echo "Error frequency by hour:"
if [ "$ERROR_COUNT" -gt 0 ]; then
    echo "00-04: $(draw_bar ${HOUR_BUCKETS[0]}) (${HOUR_BUCKETS[0]})"
    echo "04-08: $(draw_bar ${HOUR_BUCKETS[1]}) (${HOUR_BUCKETS[1]})"
    echo "08-12: $(draw_bar ${HOUR_BUCKETS[2]}) (${HOUR_BUCKETS[2]})"
    echo "12-16: $(draw_bar ${HOUR_BUCKETS[3]}) (${HOUR_BUCKETS[3]})"
    echo "16-20: $(draw_bar ${HOUR_BUCKETS[4]}) (${HOUR_BUCKETS[4]})"
    echo "20-24: $(draw_bar ${HOUR_BUCKETS[5]}) (${HOUR_BUCKETS[5]})"
else
    echo "No ERROR messages to analyze"
fi
} | tee "$REPORT_FILE"

echo "Report saved to: $REPORT_FILE"
