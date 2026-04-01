#!/bin/bash
# shellcheck source=scripts/functions.sh
source "/home/steam/server/functions.sh"

SERVER_FILES="/home/steam/server-files"

cd "$SERVER_FILES" || exit

LogAction "Starting RuneScape: DragonWilds Dedicated Server"

DEFAULT_PORT="${DEFAULT_PORT:-7777}"

SERVER_EXEC="$SERVER_FILES/RSDragonwilds/Binaries/Linux/RSDragonwildsServer-Linux-Shipping"

if [ ! -f "$SERVER_EXEC" ]; then
    LogError "Could not find server executable at: $SERVER_EXEC"
    exit 1
fi

chmod +x "$SERVER_EXEC"

LogInfo "Server starting on port ${DEFAULT_PORT} (UDP)"
LogInfo "Server name: ${SERVER_NAME}"
LogInfo "Default world: ${DEFAULT_WORLD_NAME}"

LAUNCH_ARGS="RSDragonwilds -log -NewConsole -Port=${DEFAULT_PORT} -ini:Game:[/Script/Engine.GameSession]:MaxPlayers=${MAX_PLAYERS}"

if [ -n "${MULTIHOME}" ]; then
    LogInfo "Multihome: ${MULTIHOME}"
    LAUNCH_ARGS="${LAUNCH_ARGS} -MULTIHOME=${MULTIHOME}"
fi

exec "$SERVER_EXEC" $LAUNCH_ARGS
