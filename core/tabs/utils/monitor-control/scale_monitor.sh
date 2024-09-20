#!/bin/sh -e

. ../utility_functions.sh

. ../../common-script.sh

# Function to scale smaller monitors to the highest resolution of a bigger monitor
scale_monitors() {
    printf "%b\n" "${YELLOW}=========================================${RC}"
    printf "%b\n" "${YELLOW}  Scale Monitors to Highest Resolution${RC}"
    printf "%b\n" "${YELLOW}=========================================${RC}"

    monitor_list=$(detect_connected_monitors)
    monitor_array=$(echo "$monitor_list" | tr '\n' ' ')

    max_width=0
    max_height=0

    for monitor in $monitor_array; do
        res=$(xrandr | grep -A1 "^$monitor connected" | tail -1 | awk '{print $1}')
        width=$(echo "$res" | awk -Fx '{print $1}')
        height=$(echo "$res" | awk -Fx '{print $2}')

        if [ "$width" -gt "$max_width" ]; then
            max_width=$width
        fi

        if [ "$height" -gt "$max_height" ]; then
            max_height=$height
        fi
    done

    printf "%b\n" "${YELLOW}Highest resolution found: ${max_width}x${max_height}${RC}"

    for monitor in $monitor_array; do
        printf "%b\n" "${YELLOW}Scaling $monitor to ${max_width}x${max_height}${RC}"
        execute_command "xrandr --output $monitor --scale-from ${max_width}x${max_height}"
    done

    printf "%b\n" "${GREEN}Scaling complete. All monitors are now scaled to ${max_width}x${max_height}.${RC}"
}

# Call the scale_monitors function
scale_monitors
