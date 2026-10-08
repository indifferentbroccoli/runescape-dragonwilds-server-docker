#!/bin/bash
# shellcheck source=scripts/functions.sh
source "/home/steam/server/functions.sh"

SERVER_FILES="/home/steam/server-files"

cd "$SERVER_FILES" || exit

LogAction "Starting RuneScape: DragonWilds Dedicated Server"

DEFAULT_PORT="${DEFAULT_PORT:-7777}"

if [ "${UE4SS_ENABLED}" = "true" ]; then
    SERVER_EXEC="$SERVER_FILES/RSDragonwilds/Binaries/Win64/RSDragonwildsServer-Win64-Shipping.exe"
else
    SERVER_EXEC="$SERVER_FILES/RSDragonwilds/Binaries/Linux/RSDragonwildsServer-Linux-Shipping"
fi

if [ ! -f "$SERVER_EXEC" ]; then
    LogError "Could not find server executable at: $SERVER_EXEC"
    exit 1
fi

LogInfo "Server starting on port ${DEFAULT_PORT} (UDP)"
LogInfo "World settings beacon port: ${BEACON_PORT} (UDP)"
LogInfo "Server name: ${SERVER_NAME}"
LogInfo "Default world: ${DEFAULT_WORLD_NAME}"

LAUNCH_ARGS="RSDragonwilds -Port=${DEFAULT_PORT} -BeaconPort=${BEACON_PORT} -ini:Game:[/Script/Engine.GameSession]:MaxPlayers=${MAX_PLAYERS}"

if [ -n "${MULTIHOME}" ]; then
    LogInfo "Multihome: ${MULTIHOME}"
    LAUNCH_ARGS="${LAUNCH_ARGS} -MULTIHOME=${MULTIHOME}"
fi

if [ "${UE4SS_ENABLED}" != "true" ]; then
    chmod +x "$SERVER_EXEC"
    exec "$SERVER_EXEC" $LAUNCH_ARGS -log -NewConsole
fi

LogInfo "UE4SS enabled, running the Windows server build through Wine"

tail -q -n 0 -F "$SERVER_FILES/RSDragonwilds/Saved/Logs/RSDragonwilds.log" 2>/dev/null &
tail_pid=$!

export WINEDLLOVERRIDES="dwmapi,version=n,b"

wine "$SERVER_EXEC" $LAUNCH_ARGS -log > /dev/null
status=$?

kill "$tail_pid" 2>/dev/null
exit "$status"
