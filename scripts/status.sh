#!/bin/bash
################################################################################
# Status and Monitoring Script for Email Security Scanner
# Shows current system status and statistics
################################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Email Security Scanner - Status${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Count files in each directory
INBOX_COUNT=$(find "${PROJECT_ROOT}/inbox" -type f ! -name ".gitkeep" 2>/dev/null | wc -l)
CLEAN_COUNT=$(find "${PROJECT_ROOT}/clean" -type f ! -name ".gitkeep" 2>/dev/null | wc -l)
INFECTED_COUNT=$(find "${PROJECT_ROOT}/infected" -type f ! -name ".gitkeep" 2>/dev/null | wc -l)
QUARANTINE_COUNT=$(find "${PROJECT_ROOT}/quarantine" -type f ! -name ".gitkeep" 2>/dev/null | wc -l)
PROCESSED_COUNT=$(find "${PROJECT_ROOT}/processed" -type f 2>/dev/null | wc -l)

echo "📊 File Statistics:"
echo "  Inbox (pending):     $INBOX_COUNT file(s)"
echo "  Clean:               $CLEAN_COUNT file(s)"
echo "  Infected:            ${RED}$INFECTED_COUNT file(s)${NC}"
echo "  Quarantine:          ${YELLOW}$QUARANTINE_COUNT file(s)${NC}"
echo "  Processed:           $PROCESSED_COUNT email(s)"
echo ""

# Check if log file exists
if [[ -f "${PROJECT_ROOT}/logs/email_scanner.log" ]]; then
    echo "📝 Recent Log Entries:"
    echo "---"
    tail -n 10 "${PROJECT_ROOT}/logs/email_scanner.log" | while IFS= read -r line; do
        if [[ "$line" =~ WARN|ERROR ]]; then
            echo -e "${YELLOW}$line${NC}"
        elif [[ "$line" =~ INFO ]]; then
            echo -e "${GREEN}$line${NC}"
        else
            echo "$line"
        fi
    done
    echo "---"
    echo ""
else
    echo -e "${YELLOW}No log file found yet${NC}"
    echo ""
fi

# Check cron job status
echo "⏰ Cron Job Status:"
if crontab -l 2>/dev/null | grep -q "process_emails.sh"; then
    echo -e "  ${GREEN}✓${NC} Cron job is installed"
    echo "  Active cron entries:"
    crontab -l 2>/dev/null | grep "process_emails.sh" | sed 's/^/    /'
else
    echo -e "  ${YELLOW}✗${NC} Cron job not installed"
    echo "  To install: crontab -e"
    echo "  See: ${PROJECT_ROOT}/config/cron_config.txt"
fi
echo ""

# Check dependencies
echo "🔧 Dependencies:"
deps=("bash" "curl" "md5sum" "clamscan" "munpack")
for dep in "${deps[@]}"; do
    if command -v "$dep" &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $dep"
    else
        echo -e "  ${YELLOW}✗${NC} $dep (optional)"
    fi
done
echo ""

# Check configuration
echo "⚙️  Configuration:"
if [[ -f "${PROJECT_ROOT}/config/email_scanner.conf" ]]; then
    source "${PROJECT_ROOT}/config/email_scanner.conf"
    echo "  Cuckoo Enabled: $CUCKOO_ENABLED"
    echo "  Fallback Mode:  $FALLBACK_MODE"
    echo "  Log Level:      $LOG_LEVEL"
else
    echo -e "  ${RED}Configuration file not found!${NC}"
fi
echo ""

# Show infected files if any
if [[ $INFECTED_COUNT -gt 0 ]]; then
    echo -e "${RED}⚠️  Warning: Infected Files Detected!${NC}"
    echo "Files in infected directory:"
    ls -lh "${PROJECT_ROOT}/infected" | grep -v "^total" | grep -v ".gitkeep" | sed 's/^/  /'
    echo ""
fi

# Show quarantine files if any
if [[ $QUARANTINE_COUNT -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  Quarantined Files (require manual review):${NC}"
    echo "Files in quarantine directory:"
    ls -lh "${PROJECT_ROOT}/quarantine" | grep -v "^total" | grep -v ".gitkeep" | sed 's/^/  /'
    echo ""
fi

echo -e "${BLUE}========================================${NC}"
echo ""
echo "Commands:"
echo "  Process emails now:  ./scripts/process_emails.sh"
echo "  View logs:          tail -f logs/email_scanner.log"
echo "  Setup system:       ./scripts/setup.sh"
echo ""
