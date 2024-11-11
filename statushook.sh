#!/bin/bash

LOG_FILE="/var/log/lxchook.log"
echo "$(date): Hookscript triggered with args: $1 $2" >> $LOG_FILE

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

# Function to send a Discord notification
send_discord_notification() {
    local webhook_url=$1
    local message=$2
    echo "$(date): Sending message: $message" >> $LOG_FILE

    # Run the curl command in the background and ignore errors
    {
        curl -s -H "Content-Type: application/json" \
             -X POST \
             -d "{\"content\": \"$message\"}" \
             $webhook_url
    } || {
        echo "$(date): Failed to send message to Discord." >> $LOG_FILE
    } &
}

# Check the event type and send appropriate notifications
if [ "$event_type" = "pre-start" ]; then
    message="\uD83D\uDFE2 LXC container $container_id is starting."
elif [ "$event_type" = "post-stop" ]; then
    message="\uD83D\uDD34 LXC container $container_id has stopped."
elif [ "$event_type" = "post-start" ]; then
    message="\uD83D\uDFE2 LXC container $container_id has started."
elif [ "$event_type" = "pre-stop" ]; then
    message="\uD83D\uDD34 LXC container $container_id is stopping."
else
    echo "$(date): Hook script exiting, event not handled." >> $LOG_FILE
    exit 0
fi

# Send the notification (non-blocking, ignore failures)
send_discord_notification "${container_webhooks[$container_id]}" "$message" || true
