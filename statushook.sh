#!/bin/bash

LOG_FILE="/var/log/lxchook.log"

# Logging function
log_message() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# Log the initial hook event
log_message "Hookscript triggered with args: $1 $2"

# Define the container ID
container_id=$1
# Grab the event type from the hook
event_type=$2

# Map LXC container IDs to their respective webhooks
declare -A container_webhooks
# Container 1
container_webhooks[100]="https://discordapp.com/api/webhooks/WEBHOOK_KEY_FOR_CONTAINER_1"
# Container 2
container_webhooks[101]="https://discordapp.com/api/webhooks/WEBHOOK_KEY_FOR_CONTAINER_2"
# Container 3
container_webhooks[102]="https://discordapp.com/api/webhooks/WEBHOOK_KEY_FOR_CONTAINER_3"
# Container 4
container_webhooks[103]="https://discordapp.com/api/webhooks/WEBHOOK_KEY_FOR_CONTAINER_4"
# Container 5
container_webhooks[104]="https://discordapp.com/api/webhooks/WEBHOOK_KEY_FOR_CONTAINER_5"

# Containers that need ZFS pool checks
declare -a zfs_containers=("1xx" "1xx" "1xx")

# Define ZFS pool name and mount point
zfs_name="pool-name"
zfs_mountpoint="/mnt/pool-mountpoint"

# Function to send a Discord notification
send_discord_notification() {
    local webhook_url=$1
    local message=$2
    log_message "Sending message: $message"

    # Run the curl command in the background and ignore errors
    {
        curl -s -H "Content-Type: application/json" \
             -X POST \
             -d "{\"content\": \"$message\"}" \
             $webhook_url
    } || {
        log_message "Failed to send message to Discord."
    } &
}

# Function to check if ZFS pool is ready
check_zfs_mount() {
    local pool=$1
    local mountpoint=$2
    local max_retries=20
    local retry_delay=3
    local count=0

    log_message "Checking if ZFS pool '$pool' is ready and mounted at '$mountpoint'."

    while [ "$count" -lt "$max_retries" ]; do
        if zpool status "$pool" | grep -q "ONLINE" && mount | grep -q "$mountpoint"; then
            log_message "ZFS pool '$pool' is online and mounted at '$mountpoint'."
            return 0
        fi

        log_message "Waiting for ZFS pool '$pool' to be ready... ($count/$max_retries)"
        count=$((count + 1))
        sleep "$retry_delay"
    done

    log_message "ERROR: ZFS pool '$pool' not ready after $max_retries attempts. Proceeding with container startup anyway."
    return 1
}

# Helper function to check if a value exists in an array
is_in_array() {
    local value=$1
    shift
    for element in "$@"; do
        if [[ "$element" == "$value" ]]; then
            return 0
        fi
    done
    return 1
}

# Check the event type and send appropriate notifications
if [ "$event_type" = "pre-start" ]; then
    # Check if this container requires ZFS mount readiness
    if is_in_array "$container_id" "${zfs_containers[@]}"; then
        check_zfs_mount "$zfs_name" "$zfs_mountpoint"
    fi
    message="\uD83D\uDFE2 LXC container $container_id is starting."
elif [ "$event_type" = "post-stop" ]; then
    message="\uD83D\uDD34 LXC container $container_id has stopped."
elif [ "$event_type" = "post-start" ]; then
    message="\uD83D\uDFE2 LXC container $container_id has started."
elif [ "$event_type" = "pre-stop" ]; then
    message="\uD83D\uDD34 LXC container $container_id is stopping."
else
    log_message "Hook script exiting, event not handled."
    exit 0
fi

# Send the notification (non-blocking, ignore failures)
send_discord_notification "${container_webhooks[$container_id]}" "$message" || true
