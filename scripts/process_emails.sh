#!/bin/bash
################################################################################
# Email Attachment Security Scanner
# This script processes emails from an inbox, extracts attachments,
# scans them for malware using a sandbox or fallback methods,
# and moves them to appropriate folders based on the scan results.
################################################################################

set -uo pipefail

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load configuration
CONFIG_FILE="${PROJECT_ROOT}/config/email_scanner.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "ERROR: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Function to extract attachments from email files
extract_attachments() {
    local email_file=$1
    local output_dir=$2
    
    log "INFO" "Extracting attachments from: $email_file"
    
    # Create temporary directory for this email
    local temp_dir=$(mktemp -d)
    
    # Check if the email file has attachments
    # This is a simplified version - for real emails, use munpack or similar
    if grep -q "Content-Disposition: attachment" "$email_file" 2>/dev/null; then
        # Extract attachment using munpack if available, otherwise manual extraction
        if command -v munpack &> /dev/null; then
            munpack -C "$temp_dir" "$email_file" 2>/dev/null || log "WARN" "munpack failed for $email_file"
        else
            # Manual extraction for simple base64 attachments
            log "INFO" "munpack not available, attempting manual extraction"
            manual_extract_attachment "$email_file" "$temp_dir"
        fi
    else
        log "INFO" "No attachments found in $email_file"
    fi
    
    # Move extracted files to output directory
    if [ -d "$temp_dir" ] && [ "$(ls -A $temp_dir)" ]; then
        mv "$temp_dir"/* "$output_dir/" 2>/dev/null || true
        log "INFO" "Extracted attachments moved to: $output_dir"
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
}

# Manual extraction for simple attachments
manual_extract_attachment() {
    local email_file=$1
    local output_dir=$2
    
    # Extract filename from Content-Disposition header
    local filename=$(grep -A 5 "Content-Disposition: attachment" "$email_file" | grep "filename=" | head -1 | sed 's/.*filename="\([^"]*\)".*/\1/' || echo "attachment_$(date +%s)")
    
    # Find base64 content and decode
    awk '/Content-Transfer-Encoding: base64/,/^--/' "$email_file" | grep -v "Content-Transfer-Encoding" | grep -v "^--" | base64 -d > "$output_dir/$filename" 2>/dev/null || true
}

# Function to calculate file hash
calculate_hash() {
    local file=$1
    md5sum "$file" | awk '{print $1}'
}

# Function to check if hash is in malware database
is_malware_hash() {
    local hash=$1
    for known_hash in "${MALWARE_HASHES[@]}"; do
        if [[ "$hash" == "$known_hash" ]]; then
            return 0  # True - it's malware
        fi
    done
    return 1  # False - not in malware list
}

# Function to scan file with ClamAV
scan_with_clamav() {
    local file=$1
    
    if ! command -v clamscan &> /dev/null; then
        log "INFO" "ClamAV not installed"
        return 2  # Unknown
    fi
    
    log "INFO" "Scanning with ClamAV: $file"
    if clamscan --no-summary "$file" 2>&1 | grep -q "FOUND"; then
        log "WARN" "ClamAV detected malware: $file"
        return 1  # Infected
    else
        log "INFO" "ClamAV scan clean: $file"
        return 0  # Clean
    fi
}

# Function to submit file to Cuckoo Sandbox
submit_to_cuckoo() {
    local file=$1
    
    if [[ "$CUCKOO_ENABLED" != "true" ]]; then
        log "INFO" "Cuckoo Sandbox is disabled"
        return 2  # Unknown
    fi
    
    if ! command -v curl &> /dev/null; then
        log "WARN" "curl not installed, cannot connect to Cuckoo"
        return 2  # Unknown
    fi
    
    log "INFO" "Submitting to Cuckoo Sandbox: $file"
    
    # Submit file to Cuckoo
    local response=$(curl -s -F file=@"$file" "${CUCKOO_API_URL}/tasks/create/file" -H "Authorization: Bearer ${CUCKOO_API_TOKEN}" 2>/dev/null || echo "")
    
    if [[ -z "$response" ]]; then
        log "WARN" "Failed to submit to Cuckoo Sandbox"
        return 2  # Unknown
    fi
    
    # Extract task ID from response
    local task_id=$(echo "$response" | grep -o '"task_id":[0-9]*' | cut -d':' -f2)
    
    if [[ -z "$task_id" ]]; then
        log "WARN" "Failed to get task ID from Cuckoo"
        return 2  # Unknown
    fi
    
    log "INFO" "Cuckoo task ID: $task_id"
    
    # Wait for analysis to complete (with timeout)
    local max_wait=300  # 5 minutes
    local waited=0
    local status=""
    
    while [[ $waited -lt $max_wait ]]; do
        sleep 10
        waited=$((waited + 10))
        
        status=$(curl -s "${CUCKOO_API_URL}/tasks/view/${task_id}" -H "Authorization: Bearer ${CUCKOO_API_TOKEN}" 2>/dev/null | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        
        if [[ "$status" == "reported" ]]; then
            break
        fi
        
        log "INFO" "Waiting for Cuckoo analysis... (${waited}s)"
    done
    
    if [[ "$status" != "reported" ]]; then
        log "WARN" "Cuckoo analysis timeout"
        return 2  # Unknown
    fi
    
    # Get report
    local report=$(curl -s "${CUCKOO_API_URL}/tasks/report/${task_id}" -H "Authorization: Bearer ${CUCKOO_API_TOKEN}" 2>/dev/null || echo "")
    
    # Check for malware indicators (simplified)
    if echo "$report" | grep -q '"score":[5-9]' || echo "$report" | grep -q '"score":10'; then
        log "WARN" "Cuckoo detected suspicious/malicious activity: $file"
        return 1  # Infected
    else
        log "INFO" "Cuckoo analysis clean: $file"
        return 0  # Clean
    fi
}

# Function to scan a file using available methods
scan_file() {
    local file=$1
    local result=2  # Default: unknown
    
    log "INFO" "Scanning file: $file"
    
    # Calculate hash
    local file_hash=$(calculate_hash "$file")
    log "INFO" "File hash (MD5): $file_hash"
    
    # Check hash against known malware
    if is_malware_hash "$file_hash"; then
        log "WARN" "File matches known malware hash: $file"
        return 1  # Infected
    fi
    
    # Try Cuckoo Sandbox first
    if [[ "$CUCKOO_ENABLED" == "true" ]]; then
        submit_to_cuckoo "$file"
        result=$?
        if [[ $result -ne 2 ]]; then
            return $result
        fi
    fi
    
    # Fallback to other methods
    case "$FALLBACK_MODE" in
        clamav)
            scan_with_clamav "$file"
            return $?
            ;;
        simulate)
            # Simulate scan based on filename patterns
            if [[ "$file" =~ malware|virus|infected|trojan ]]; then
                log "WARN" "Simulation: File name suggests malware: $file"
                return 1  # Infected
            else
                log "INFO" "Simulation: File appears clean: $file"
                return 0  # Clean
            fi
            ;;
        hash)
            # Already checked hash above
            log "INFO" "Hash check passed: $file"
            return 0  # Clean (not in malware list)
            ;;
        *)
            log "WARN" "Unknown fallback mode: $FALLBACK_MODE"
            return 2  # Unknown
            ;;
    esac
}

# Function to process a single email
process_email() {
    local email_file=$1
    
    log "INFO" "Processing email: $email_file"
    
    # Create temporary directory for attachments
    local temp_dir=$(mktemp -d)
    
    # Extract attachments
    extract_attachments "$email_file" "$temp_dir"
    
    # Scan each attachment
    if [ -d "$temp_dir" ] && [ "$(ls -A $temp_dir)" ]; then
        for attachment in "$temp_dir"/*; do
            if [[ -f "$attachment" ]]; then
                local filename=$(basename "$attachment")
                log "INFO" "Processing attachment: $filename"
                
                # Scan the file
                scan_file "$attachment"
                local scan_result=$?
                
                case $scan_result in
                    0)
                        # Clean
                        log "INFO" "Moving clean file to: $CLEAN_DIR"
                        mv "$attachment" "$CLEAN_DIR/"
                        ;;
                    1)
                        # Infected
                        log "WARN" "Moving infected file to: $INFECTED_DIR"
                        mv "$attachment" "$INFECTED_DIR/"
                        ;;
                    *)
                        # Unknown
                        log "WARN" "Moving unknown file to: $QUARANTINE_DIR"
                        mv "$attachment" "$QUARANTINE_DIR/"
                        ;;
                esac
            fi
        done
    else
        log "INFO" "No attachments to process in: $email_file"
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    
    # Archive the processed email (move to processed folder)
    local processed_dir="${PROJECT_ROOT}/processed"
    mkdir -p "$processed_dir"
    mv "$email_file" "$processed_dir/"
    
    log "INFO" "Email processed successfully: $email_file"
}

# Main function
main() {
    log "INFO" "=========================================="
    log "INFO" "Email Security Scanner Started"
    log "INFO" "=========================================="
    log "INFO" "Configuration:"
    log "INFO" "  Inbox: $INBOX_DIR"
    log "INFO" "  Clean: $CLEAN_DIR"
    log "INFO" "  Infected: $INFECTED_DIR"
    log "INFO" "  Quarantine: $QUARANTINE_DIR"
    log "INFO" "  Cuckoo Enabled: $CUCKOO_ENABLED"
    log "INFO" "  Fallback Mode: $FALLBACK_MODE"
    log "INFO" "=========================================="
    
    # Check if inbox directory exists
    if [[ ! -d "$INBOX_DIR" ]]; then
        log "ERROR" "Inbox directory not found: $INBOX_DIR"
        exit 1
    fi
    
    # Create necessary directories
    mkdir -p "$CLEAN_DIR" "$INFECTED_DIR" "$QUARANTINE_DIR" "$LOG_DIR"
    
    # Process all emails in inbox
    local email_count=0
    shopt -s nullglob
    for email_file in "$INBOX_DIR"/*; do
        if [[ -f "$email_file" ]]; then
            process_email "$email_file"
            email_count=$((email_count + 1))
        fi
    done
    shopt -u nullglob
    
    log "INFO" "=========================================="
    log "INFO" "Email Security Scanner Finished"
    log "INFO" "Processed $email_count email(s)"
    log "INFO" "=========================================="
}

# Run main function
main "$@"
