#!/bin/bash
# shellcheck source=scripts/functions.sh
source "/home/steam/server/functions.sh"

SERVER_FILES="/home/steam/server-files"

cd "$SERVER_FILES" || exit

LogAction "Starting RuneScape: DragonWilds Dedicated Server"

# Validate required config
if [ -z "${OWNER_ID}" ]; then
    LogError "OWNER_ID is not set. The server cannot start without your RuneScape: DragonWilds Player ID."
    LogError "Find your Player ID in-game at the bottom of the Settings Menu."
    exit 1
fi

DEFAULT_PORT="${DEFAULT_PORT:-7777}"
SERVER_NAME="${SERVER_NAME:-DragonWildsServer}"
DEFAULT_WORLD_NAME="${DEFAULT_WORLD_NAME:-MyWorld}"

# Write DedicatedServer.ini
CONFIG_DIR="$SERVER_FILES/RSDragonwilds/Saved/Config/LinuxServer"
CONFIG_FILE="$CONFIG_DIR/DedicatedServer.ini"

mkdir -p "$CONFIG_DIR"

LogInfo "Generating DedicatedServer.ini from environment variables"

cat > "$CONFIG_FILE" <<EOF
[ServerSettings]
OwnerID=${OWNER_ID}
ServerName=${SERVER_NAME}
DefaultWorldName=${DEFAULT_WORLD_NAME}
AdminPassword=${ADMIN_PASSWORD}
WorldPassword=${WORLD_PASSWORD}
Port=${DEFAULT_PORT}
EOF

LogSuccess "DedicatedServer.ini written to $CONFIG_FILE"

SERVER_EXEC="$SERVER_FILES/RSDragonwilds/Binaries/Linux/RSDragonwilds-Linux-Shipping"

if [ ! -f "$SERVER_EXEC" ]; then
    LogError "Could not find server executable at: $SERVER_EXEC"
    exit 1
fi

chmod +x "$SERVER_EXEC"

LogInfo "Server starting on port ${DEFAULT_PORT} (UDP)"
LogInfo "Server name: ${SERVER_NAME}"
LogInfo "Default world: ${DEFAULT_WORLD_NAME}"

exec "$SERVER_EXEC" -log -NewConsole -Port="${DEFAULT_PORT}"
