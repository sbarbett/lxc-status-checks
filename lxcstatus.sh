#!/bin/bash

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
# ...and so on. You could just have all your notifications go to the same channel if you want.

# Function to send a Discord alert
send_discord_alert() {
    local webhook_url=$1
    local message=$2
    curl -H "Content-Type: application/json" \
         -X POST \
         -d "{\"content\": \"$message\"}" \
         $webhook_url
}

# Loop through each container and check its status
for container_id in "${!container_webhooks[@]}"; do
    # Check if the container is running
    container_status=$(sudo pct status $container_id)

    # Extract the container's status (e.g., running or stopped)
    if [[ $container_status == *"stopped"* ]]; then
        # Container is stopped, send an alert to the respective webhook
        send_discord_alert "${container_webhooks[$container_id]}" "\u26A0\uFE0F LXC container $container_id is stopped."
        echo "$(date): LXC container $container_id is stopped."
    elif [[ $container_status == *"running"* ]]; then
        # Container is running, log but don't notify
        echo "$(date): LXC container $container_id is running."
    else
        # Unhandled status, send an alert with unknown status
        send_discord_alert "${container_webhooks[$container_id]}" "\u26A0\uFE0F LXC container $container_id has an unknown status: $container_status."
        echo "$(date): LXC container $container_id has an unknown status: $container_status."
    fi
done
