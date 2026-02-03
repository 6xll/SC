#!/bin/bash
################################################################################
# Setup Script for Email Security Scanner
# This script helps set up the email security scanner system
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Email Security Scanner - Setup${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check for required commands
echo "Checking dependencies..."

check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is NOT installed"
        return 1
    fi
}

# Check basic requirements
check_command "bash" || exit 1
check_command "curl" || echo -e "${YELLOW}Warning: curl not found. Cuckoo integration will not work.${NC}"
check_command "md5sum" || exit 1

# Optional tools
echo ""
echo "Checking optional tools..."
check_command "clamscan" || echo -e "${YELLOW}Tip: Install ClamAV for virus scanning (apt-get install clamav clamav-daemon)${NC}"
check_command "munpack" || echo -e "${YELLOW}Tip: Install mpack for better email parsing (apt-get install mpack)${NC}"

echo ""
echo "Creating directory structure..."
mkdir -p "${PROJECT_ROOT}/inbox"
mkdir -p "${PROJECT_ROOT}/clean"
mkdir -p "${PROJECT_ROOT}/infected"
mkdir -p "${PROJECT_ROOT}/quarantine"
mkdir -p "${PROJECT_ROOT}/logs"
mkdir -p "${PROJECT_ROOT}/processed"
mkdir -p "${PROJECT_ROOT}/config"
mkdir -p "${PROJECT_ROOT}/scripts"
echo -e "${GREEN}✓${NC} Directories created"

echo ""
echo "Setting permissions..."
chmod +x "${PROJECT_ROOT}/scripts/process_emails.sh" 2>/dev/null || true
echo -e "${GREEN}✓${NC} Permissions set"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Review and edit the configuration file:"
echo "   ${PROJECT_ROOT}/config/email_scanner.conf"
echo ""
echo "2. Test the scanner manually:"
echo "   ${PROJECT_ROOT}/scripts/process_emails.sh"
echo ""
echo "3. Set up the cron job:"
echo "   crontab -e"
echo "   Add a line from: ${PROJECT_ROOT}/config/cron_config.txt"
echo ""
echo "4. Place test emails in the inbox folder:"
echo "   ${PROJECT_ROOT}/inbox/"
echo ""
echo -e "${YELLOW}Note: If you want to use Cuckoo Sandbox:${NC}"
echo "  - Install Cuckoo Sandbox (https://cuckoosandbox.org/)"
echo "  - Configure CUCKOO_API_URL and CUCKOO_API_TOKEN in the config file"
echo "  - Set CUCKOO_ENABLED=true"
echo ""
echo -e "${YELLOW}Note: If you want to use ClamAV:${NC}"
echo "  - Install ClamAV: sudo apt-get install clamav clamav-daemon"
echo "  - Update virus definitions: sudo freshclam"
echo "  - Set FALLBACK_MODE=clamav in the config file"
echo ""
