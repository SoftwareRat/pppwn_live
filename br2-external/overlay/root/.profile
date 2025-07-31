# PPPwn Live System - Root Profile
# This profile is executed when root user logs in

# Set environment variables
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export TERM="linux"
export HOME="/root"

# Source system-wide profile if it exists
[ -f /etc/profile ] && . /etc/profile

# Source PPPwn configuration
[ -f /etc/pppwn/config ] && . /etc/pppwn/config

# Function to show main menu
show_main_menu() {
    echo
    echo -e "\033[1;36m╔══════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;36m║                    PPPwn Live System                         ║\033[0m"
    echo -e "\033[1;36m║                      Main Menu                               ║\033[0m"
    echo -e "\033[1;36m╠══════════════════════════════════════════════════════════════╣\033[0m"
    echo -e "\033[1;36m║\033[0m  \033[1;32m1.\033[0m Start PPPwn Exploit (Automatic)                      \033[1;36m║\033[0m"
    echo -e "\033[1;36m║\033[0m  \033[1;32m2.\033[0m Run Network Detection                                \033[1;36m║\033[0m"
    echo -e "\033[1;36m║\033[0m  \033[1;32m3.\033[0m Show System Status                                   \033[1;36m║\033[0m"
    echo -e "\033[1;36m║\033[0m  \033[1;32m4.\033[0m Manual Shell Access                                  \033[1;36m║\033[0m"
    echo -e "\033[1;36m║\033[0m  \033[1;32m5.\033[0m Emergency Shell (Troubleshooting)                   \033[1;36m║\033[0m"
    echo -e "\033[1;36m║\033[0m  \033[1;32m6.\033[0m System Shutdown                                      \033[1;36m║\033[0m"
    echo -e "\033[1;36m║\033[0m  \033[1;32m7.\033[0m Help & Troubleshooting                               \033[1;36m║\033[0m"
    echo -e "\033[1;36m╚══════════════════════════════════════════════════════════════╝\033[0m"
    echo
}

# Function to handle user menu choice
handle_menu_choice() {
    local choice="$1"
    
    case "$choice" in
        1|"")
            echo "Starting PPPwn exploit..."
            if [ -x /usr/bin/pppwn-runner ]; then
                /usr/bin/pppwn-runner
            else
                echo "ERROR: PPPwn runner not found"
                echo "Press Enter to return to menu..."
                read
            fi
            ;;
        2)
            echo "Running network detection..."
            if [ -x /usr/bin/network-detector ]; then
                /usr/bin/network-detector
                echo "Network detection completed. Press Enter to continue..."
                read
            else
                echo "ERROR: Network detector not found"
                echo "Press Enter to return to menu..."
                read
            fi
            ;;
        3)
            echo "System Status:"
            echo "=============="
            /usr/bin/status-display sysinfo
            
            # Show service status
            echo
            echo "Service Status:"
            for service in S95pppwn-setup S96service-monitor S98network-detect; do
                printf "  %-20s: " "$service"
                /etc/init.d/$service status >/dev/null 2>&1
                if [ $? -eq 0 ]; then
                    echo -e "\033[1;32mRUNNING\033[0m"
                else
                    echo -e "\033[1;31mSTOPPED\033[0m"
                fi
            done
            
            echo
            echo "Press Enter to return to menu..."
            read
            ;;
        4)
            echo "Entering manual shell mode..."
            echo "Type 'exit' to return to the main menu"
            echo
            return 0  # Exit to shell
            ;;
        5)
            echo "Entering emergency shell..."
            if [ -x /usr/bin/emergency-shell ]; then
                /usr/bin/emergency-shell
            else
                echo "Emergency shell not available"
                echo "Press Enter to continue..."
                read
            fi
            ;;
        6)
            echo "Initiating system shutdown..."
            if [ -x /usr/bin/secure-shutdown ]; then
                /usr/bin/secure-shutdown manual "User requested shutdown"
            else
                /sbin/shutdown -h now
            fi
            ;;
        7)
            show_help_menu
            ;;
        *)
            echo "Invalid choice: $choice"
            echo "Press Enter to try again..."
            read
            ;;
    esac
}

# Function to show help menu
show_help_menu() {
    echo
    echo -e "\033[1;33m╔══════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;33m║                  Help & Troubleshooting                      ║\033[0m"
    echo -e "\033[1;33m╚══════════════════════════════════════════════════════════════╝\033[0m"
    echo
    echo -e "\033[1;36mCommon Issues:\033[0m"
    echo "• Network detection fails:"
    echo "  - Check Ethernet cable connection"
    echo "  - Ensure PS4 is powered on"
    echo "  - Try option 2 to manually run network detection"
    echo
    echo "• PPPwn exploit fails:"
    echo "  - Verify PS4 firmware version is supported"
    echo "  - Ensure PS4 is at main menu (not in game or app)"
    echo "  - Multiple attempts are normal - be patient"
    echo
    echo "• System appears frozen:"
    echo "  - Press Ctrl+C to interrupt current operation"
    echo "  - Use option 4 for manual shell access"
    echo
    echo -e "\033[1;36mSupported Firmware Versions:\033[0m"
    echo "• 9.00, 9.03, 9.04, 9.50, 9.51, 9.60, 10.00, 10.01, 10.50, 10.70, 10.71, 11.00"
    echo
    echo -e "\033[1;36mManual Commands:\033[0m"
    echo "• pppwn-runner      - Start PPPwn exploit"
    echo "• network-detector  - Run network detection"
    echo "• status-display    - Show formatted status messages"
    echo "• service-monitor   - Check service monitoring status"
    echo
    echo "Press Enter to return to main menu..."
    read
}

# Function to check if auto-start should be used
should_auto_start() {
    # Check if auto_start is enabled in config
    if [ "$auto_start" != "true" ]; then
        return 1
    fi
    
    # Check if network is ready
    if [ ! -f /tmp/pppwn_interface ]; then
        return 1
    fi
    
    # Check if this is the first run on tty1
    if [ "$(tty)" != "/dev/tty1" ]; then
        return 1
    fi
    
    # Check if we haven't already auto-started
    if [ -f /tmp/pppwn_auto_started ]; then
        return 1
    fi
    
    return 0
}

# Main profile execution logic
main_profile_logic() {
    # Only run interactive logic on tty1
    if [ "$(tty)" = "/dev/tty1" ]; then
        # Check for auto-start conditions
        if should_auto_start; then
            # Mark that we're auto-starting
            touch /tmp/pppwn_auto_started
            
            echo
            /usr/bin/status-display status INFO "Auto-starting PPPwn exploit..."
            /usr/bin/status-display status INFO "Press Ctrl+C within 10 seconds to cancel and access menu"
            
            # Countdown with interrupt handling
            local cancelled=false
            trap 'cancelled=true' INT
            
            for i in 10 9 8 7 6 5 4 3 2 1; do
                if [ "$cancelled" = "true" ]; then
                    echo
                    /usr/bin/status-display status INFO "Auto-start cancelled by user"
                    break
                fi
                printf "\rStarting in %d seconds... " "$i"
                sleep 1
            done
            
            trap - INT
            
            if [ "$cancelled" = "false" ]; then
                echo
                exec /usr/bin/pppwn-runner
            fi
        fi
        
        # Show interactive menu
        while true; do
            show_main_menu
            printf "Enter your choice (1-7) [1]: "
            read choice
            
            # Default to option 1 if no choice given
            [ -z "$choice" ] && choice=1
            
            handle_menu_choice "$choice"
            
            # If choice was 4 (shell), break out of loop
            if [ "$choice" = "4" ]; then
                break
            fi
        done
    else
        # Non-interactive or other TTY - just show basic info
        echo "PPPwn Live System - $(tty)"
        echo "Use 'pppwn-runner' to start the exploit or access tty1 for the main interface"
    fi
}

# Execute main logic
main_profile_logic