gnome-terminal -- bash -c '
cd ~/Desktop/tuners || { echo -e "\033[1;31m❌ Failed to enter ~/Desktop/tuners\033[0m"; exec bash; }

python3 tune_monitor.py 2>&1 | while IFS= read -r line; do
    # Check if the line has metrics
    if [[ $line == *"idle="* ]]; then
        idle=$(echo "$line" | grep -oP "idle=\K[0-9.]+")
        load=$(echo "$line" | grep -oP "load=\K[0-9./]+")
        mem_free=$(echo "$line" | grep -oP "mem_free=\K[0-9]+")
        swap_used=$(echo "$line" | grep -oP "swap_used=\K[0-9]+")
        iowait=$(echo "$line" | grep -oP "iowait=\K[0-9.]+")
        
        # Pretty-print with emojis and colors
        echo -e "🖥️  CPU Idle: \033[1;32m$idle%\033[0m | 🔼 Load: \033[1;33m$load\033[0m | 💾 Free Mem: \033[1;34m$mem_free KB\033[0m | 🗂 Swap: \033[1;35m$swap_used KB\033[0m | ⏱ IOWait: \033[1;36m$iowait%\033[0m"
    else
        # Print other lines normally
        echo -e "$line"
    fi
done

exec bash
'

