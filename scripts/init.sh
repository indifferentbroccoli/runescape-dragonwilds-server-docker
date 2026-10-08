#!/bin/bash
# shellcheck source=scripts/functions.sh
source "/home/steam/server/functions.sh"

LogAction "Set file permissions"

if [ -z "${PUID}" ] || [ -z "${PGID}" ]; then
    LogError "PUID and PGID not set. Please set these in the environment variables."
    exit 1
else
    usermod -o -u "${PUID}" steam
    groupmod -o -g "${PGID}" steam
fi

# Only chown what is needed, so each container does not get its own copy of the Wine prefix
find /home/steam \( ! -user steam -o ! -group steam \) -exec chown -h steam:steam {} +

cat /branding

if [ "${UPDATE_ON_START:-true}" = "true" ]; then
    install
else
    LogWarn "UPDATE_ON_START is set to false, skipping server update"
fi

chmod +x /home/steam/server-files/RSDragonwilds/Binaries/Linux/RSDragonwildsServer-Linux-Shipping 2>/dev/null || true
chmod +x /home/steam/server-files/RSDragonwilds/Plugins/Developer/Sentry/Binaries/Linux/crashpad_handler 2>/dev/null || true

if [ "${UE4SS_ENABLED}" = "true" ] && ! install_ue4ss; then
    LogError "UE4SS could not be installed."
    exit 1
fi

if [ -z "${OWNER_ID}" ]; then
    LogError "OWNER_ID is not set. The server cannot start without your RuneScape: DragonWilds Player ID."
    LogError "Find your Player ID in-game at the bottom of the Settings Menu."
    exit 1
fi

CONFIG_ROOT="/home/steam/server-files/RSDragonwilds/Saved/Config"
CONFIG_DIR="$CONFIG_ROOT/$SERVER_PLATFORM"
CONFIG_FILE="$CONFIG_DIR/DedicatedServer.ini"

mkdir -p "$CONFIG_DIR"

# Keep the GUID when switching between the Linux and Windows builds
SERVER_GUID=$(sed -n 's/^ServerGuid=\([0-9A-Fa-f]\+\).*/\1/p' "$CONFIG_FILE" "$CONFIG_ROOT/$OTHER_SERVER_PLATFORM/DedicatedServer.ini" 2>/dev/null | head -n1)
export SERVER_GUID

LogInfo "Writing DedicatedServer.ini"
envsubst > "$CONFIG_FILE" << 'TEMPLATE'
[SectionsToSave]
bCanSaveAllSections=true

[/Script/Dominion.DedicatedServerSettings]
AdminPassword=${ADMIN_PASSWORD}
OwnerId=${OWNER_ID}
WorldPassword=${WORLD_PASSWORD}
ServerName=${SERVER_NAME}
DefaultWorldName=${DEFAULT_WORLD_NAME}
ServerGuid=${SERVER_GUID}
TEMPLATE
chown -R steam:steam /home/steam/server-files

# shellcheck disable=SC2317
term_handler() {
    if ! shutdown_server; then
        pid=$(server_pid)
        [ -n "$pid" ] && kill -SIGKILL "$pid"
    fi
    tail --pid="$killpid" -f 2>/dev/null
}

trap 'term_handler' SIGTERM

# Start the server as steam user
export DEFAULT_PORT BEACON_PORT SERVER_NAME DEFAULT_WORLD_NAME OWNER_ID ADMIN_PASSWORD WORLD_PASSWORD MAX_PLAYERS MULTIHOME UE4SS_ENABLED

su -m steam -c "cd /home/steam/server && ./start.sh" &

killpid="$!"
wait "$killpid"
