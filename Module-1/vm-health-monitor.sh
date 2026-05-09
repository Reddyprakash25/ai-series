#!/bin/bash

################################################################################
# VM Health Monitor Script
# Purpose: Analyze Ubuntu VM health based on CPU, Memory, and Disk utilization
# Author: Reddyprakash25
# Date: 2026-05-09
#
# Health Status Logic:
#   - HEALTHY: All metrics (CPU, Memory, Disk) are BELOW 60% utilization
#   - NOT HEALTHY: Any metric is EQUAL TO or ABOVE 60% utilization
#
# Usage:
#   bash vm-health-monitor.sh              # Simple health status
#   bash vm-health-monitor.sh explain      # Detailed explanation with reasons
#   bash vm-health-monitor.sh help         # Display help information
################################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Threshold for health status (60%)
THRESHOLD=60

###############################################################################
# Function: check_os
# Description: Verify the script is running on Ubuntu
###############################################################################
check_os() {
    if [ ! -f /etc/os-release ]; then
        echo -e "${RED}Error: Cannot determine OS type${NC}"
        exit 1
    fi

    . /etc/os-release
    if [ "$ID" != "ubuntu" ]; then
        echo -e "${YELLOW}Warning: This script is optimized for Ubuntu. Current OS: $NAME${NC}"
    fi
}

###############################################################################
# Function: get_cpu_usage
# Description: Calculate CPU utilization percentage
# Returns: CPU usage as integer percentage
###############################################################################
get_cpu_usage() {
    # Get the average CPU usage from top command (1 iteration)
    local cpu_usage=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print 100 - $8}' | cut -d'.' -f1)
    
    # Fallback if top command fails
    if [ -z "$cpu_usage" ] || ! echo "$cpu_usage" | grep -q '^[0-9]*$'; then
        # Alternative method using /proc/stat
        cpu_usage=$(grep '^cpu ' /proc/stat | awk '{
            usage=($2+$4)*100/($2+$4+$5)
            printf "%d", usage
        }')
    fi
    
    # Final fallback
    if [ -z "$cpu_usage" ]; then
        cpu_usage=0
    fi
    
    echo "$cpu_usage"
}

###############################################################################
# Function: get_memory_usage
# Description: Calculate memory utilization percentage
# Returns: Memory usage as integer percentage
###############################################################################
get_memory_usage() {
    local memory_usage=$(free 2>/dev/null | grep Mem | awk '{printf("%d", ($3/$2) * 100)}')
    
    # Fallback if free command fails
    if [ -z "$memory_usage" ]; then
        memory_usage=0
    fi
    
    echo "$memory_usage"
}

###############################################################################
# Function: get_disk_usage
# Description: Calculate root filesystem disk utilization percentage
# Returns: Disk usage as integer percentage
###############################################################################
get_disk_usage() {
    local disk_usage=$(df / 2>/dev/null | tail -1 | awk '{print $(NF-1)}' | sed 's/%//')
    
    # Fallback if df command fails
    if [ -z "$disk_usage" ]; then
        disk_usage=0
    fi
    
    echo "$disk_usage"
}

###############################################################################
# Function: evaluate_health
# Description: Determine overall VM health status
# Parameters: $1=cpu_usage, $2=memory_usage, $3=disk_usage
# Returns: 0 for HEALTHY, 1 for NOT HEALTHY
###############################################################################
evaluate_health() {
    local cpu=$1
    local memory=$2
    local disk=$3
    
    # HEALTHY: All metrics < 60%
    # NOT HEALTHY: Any metric >= 60%
    if [ "$cpu" -ge "$THRESHOLD" ] || [ "$memory" -ge "$THRESHOLD" ] || [ "$disk" -ge "$THRESHOLD" ]; then
        return 1  # NOT HEALTHY
    else
        return 0  # HEALTHY
    fi
}

###############################################################################
# Function: print_simple_status
# Description: Print simple health status only
###############################################################################
print_simple_status() {
    local status=$1
    
    if [ "$status" = "HEALTHY" ]; then
        echo -e "${GREEN}[✓] VM Status: $status${NC}"
    else
        echo -e "${RED}[✗] VM Status: $status${NC}"
    fi
}

###############################################################################
# Function: print_detailed_status
# Description: Print detailed health explanation with metrics and reasons
###############################################################################
print_detailed_status() {
    local cpu=$1
    local memory=$2
    local disk=$3
    local status=$4
    
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          VM HEALTH MONITORING REPORT                       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Overall Status
    if [ "$status" = "HEALTHY" ]; then
        echo -e "${GREEN}Overall Status: ✓ HEALTHY${NC}"
    else
        echo -e "${RED}Overall Status: ✗ NOT HEALTHY${NC}"
    fi
    echo ""
    
    # CPU Status
    echo -e "${BLUE}─ CPU UTILIZATION:${NC}"
    if [ "$cpu" -lt "$THRESHOLD" ]; then
        echo -e "  ${GREEN}✓ Status: PASS${NC}"
        echo -e "  Current Usage: ${GREEN}${cpu}%${NC} (Threshold: ${THRESHOLD}%)"
        echo -e "  Reason: CPU utilization is below the ${THRESHOLD}% threshold"
    else
        echo -e "  ${RED}✗ Status: FAIL${NC}"
        echo -e "  Current Usage: ${RED}${cpu}%${NC} (Threshold: ${THRESHOLD}%)"
        echo -e "  Reason: CPU utilization exceeds the ${THRESHOLD}% threshold"
        echo -e "  Action: Consider optimizing running processes or upgrading CPU resources"
    fi
    echo ""
    
    # Memory Status
    echo -e "${BLUE}─ MEMORY UTILIZATION:${NC}"
    if [ "$memory" -lt "$THRESHOLD" ]; then
        echo -e "  ${GREEN}✓ Status: PASS${NC}"
        echo -e "  Current Usage: ${GREEN}${memory}%${NC} (Threshold: ${THRESHOLD}%)"
        echo -e "  Reason: Memory utilization is below the ${THRESHOLD}% threshold"
    else
        echo -e "  ${RED}✗ Status: FAIL${NC}"
        echo -e "  Current Usage: ${RED}${memory}%${NC} (Threshold: ${THRESHOLD}%)"
        echo -e "  Reason: Memory utilization exceeds the ${THRESHOLD}% threshold"
        echo -e "  Action: Review running processes or consider adding more RAM"
    fi
    echo ""
    
    # Disk Status
    echo -e "${BLUE}─ DISK SPACE UTILIZATION (Root Filesystem):${NC}"
    if [ "$disk" -lt "$THRESHOLD" ]; then
        echo -e "  ${GREEN}✓ Status: PASS${NC}"
        echo -e "  Current Usage: ${GREEN}${disk}%${NC} (Threshold: ${THRESHOLD}%)"
        echo -e "  Reason: Disk space utilization is below the ${THRESHOLD}% threshold"
    else
        echo -e "  ${RED}✗ Status: FAIL${NC}"
        echo -e "  Current Usage: ${RED}${disk}%${NC} (Threshold: ${THRESHOLD}%)"
        echo -e "  Reason: Disk space utilization exceeds the ${THRESHOLD}% threshold"
        echo -e "  Action: Clean up temporary files or expand storage capacity"
    fi
    echo ""
    
    # Summary
    echo -e "${BLUE}─ SUMMARY:${NC}"
    if [ "$status" = "HEALTHY" ]; then
        echo -e "  ${GREEN}All system metrics are within acceptable limits.${NC}"
        echo -e "  The VM is operating efficiently."
    else
        echo -e "  ${RED}One or more system metrics have exceeded safe thresholds.${NC}"
        echo -e "  Immediate action may be required to prevent performance degradation."
    fi
    echo ""
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

###############################################################################
# Function: print_help
# Description: Display usage information
###############################################################################
print_help() {
    cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║       VM HEALTH MONITOR - Usage Information                ║
╚════════════════════════════════════════════════════════════╝

Description:
  Analyzes Ubuntu VM health based on CPU, Memory, and Disk utilization.
  Health status is HEALTHY if all metrics are below 60% utilization.
  Health status is NOT HEALTHY if any metric exceeds 60% utilization.

Usage:
  bash vm-health-monitor.sh [OPTION]

Options:
  (no option)   Display simple VM health status
  explain       Display detailed health report with reasons and metrics
  help          Show this help message

Examples:
  # Check VM health with simple output
  $ bash vm-health-monitor.sh
  [✓] VM Status: HEALTHY

  # Get detailed explanation
  $ bash vm-health-monitor.sh explain

  # Display help
  $ bash vm-health-monitor.sh help

Health Thresholds:
  CPU Utilization:    < 60% = PASS, >= 60% = FAIL
  Memory Utilization: < 60% = PASS, >= 60% = FAIL
  Disk Utilization:   < 60% = PASS, >= 60% = FAIL

Requirements:
  - Ubuntu/Debian Linux distribution
  - Standard utilities: top, free, df
  - Bash shell

Note:
  This script should be run with appropriate permissions to access
  system metrics. For best results, run with sudo or appropriate user privileges.

EOF
}

###############################################################################
# Main Script Logic
###############################################################################
main() {
    # Check if running on Ubuntu
    check_os
    
    # Get current metrics
    cpu_usage=$(get_cpu_usage)
    memory_usage=$(get_memory_usage)
    disk_usage=$(get_disk_usage)
    
    # Evaluate health
    if evaluate_health "$cpu_usage" "$memory_usage" "$disk_usage"; then
        health_status="HEALTHY"
    else
        health_status="NOT HEALTHY"
    fi
    
    # Process command line arguments
    case "$1" in
        explain)
            print_detailed_status "$cpu_usage" "$memory_usage" "$disk_usage" "$health_status"
            ;;
        help)
            print_help
            ;;
        "")
            print_simple_status "$health_status"
            ;;
        *)
            echo -e "${RED}Error: Unknown option '$1'${NC}"
            echo "Use 'bash vm-health-monitor.sh help' for usage information"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
exit $?
