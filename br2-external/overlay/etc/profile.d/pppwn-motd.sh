#!/bin/sh
# PPPwn Live System - Message of the Day

# Only show banner on interactive shells and tty1
case "$-" in
    *i*) ;;
    *) return ;;
esac

# Only show on tty1 (main console) and only once per session
if [ "$(tty)" = "/dev/tty1" ] && [ ! -f /tmp/motd_shown_$$ ]; then
    # Mark MOTD as shown for this session
    touch /tmp/motd_shown_$$
    
    # Use status-display for consistent formatting
    /usr/bin/status-display banner
    
    echo -e "\033[1;37mWelcome to \033[1;34mPPPwn Live\033[1;37m - PS4 Jailbreak System\033[0m"
    echo
    
    # Show user guidance for initial setup
    /usr/bin/status-display guidance "Initial Setup" \
        "Connect your PS4 to this system via Ethernet cable" \
        "Ensure your PS4 is powered on and at the main menu" \
        "Verify your PS4 firmware version is supported" \
        "Wait for automatic network detection to complete"
    
    # Show system status
    echo -e "\033[1;33mSystem Status:\033[0m"
    /usr/bin/status-display sysinfo
    
    # Check network detection status
    if [ -f /tmp/pppwn-status/network ]; then
        network_status=$(cat /tmp/pppwn-status/network)
        case "$network_status" in
            "READY")
                local interface=$(cat /tmp/pppwn_interface 2>/dev/null || echo "unknown")
                local ip=$(cat /tmp/pppwn_ip 2>/dev/null || echo "unknown")
                /usr/bin/status-display status SUCCESS "Network configured: $interface ($ip)"
                /usr/bin/status-display status INFO "System is ready for PPPwn execution"
                ;;
            "FAILED"|"ERROR")
                /usr/bin/status-display status ERROR "Network detection failed"
                /usr/bin/status-display status INFO "Check your Ethernet connection and try manual detection"
                ;;
            "TIMEOUT")
                /usr/bin/status-display status WARNING "Network detection timed out"
                /usr/bin/status-display status INFO "Try manual network detection from the menu"
                ;;
            "WAITING")
                /usr/bin/status-display status INFO "Network detection in progress..."
                /usr/bin/status-display status INFO "Please wait for automatic setup to complete"
                ;;
            *)
                /usr/bin/status-display status WARNING "Network status unknown"
                ;;
        esac
    else
        /usr/bin/status-display status INFO "Network detection starting..."
    fi
    
    echo
    echo -e "\033[1;36mQuick Commands:\033[0m"
    echo "  pppwn-runner      - Start the PPPwn exploit"
    echo "  network-detector  - Manually run network detection"
    echo "  status-display    - Display system status and messages"
    echo "  service-monitor   - Check service monitoring status"
    echo
    
    echo -e "\033[1;31mCredits:\033[0m"
    echo -e "- \033[1;34mxfangfang\033[0m (https://github.com/xfangfang/PPPwn_cpp) for the C++ PPPwn implementation"
    echo -e "- \033[1;34mTheFloW\033[0m (https://github.com/TheOfficialFloW/PPPwn) for the original PPPwn discovery"
    echo
fi