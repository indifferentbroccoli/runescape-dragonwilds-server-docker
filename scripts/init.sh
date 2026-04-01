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

chown -R steam:steam /home/steam/

cat /branding

if [ "${UPDATE_ON_START:-true}" = "true" ]; then
    install
else
    LogWarn "UPDATE_ON_START is set to false, skipping server update"
fi

chown -R steam:steam /home/steam/server-files
chmod +x /home/steam/server-files/RSDragonwilds/Binaries/Linux/RSDragonwildsServer-Linux-Shipping 2>/dev/null || true
chmod +x /home/steam/server-files/RSDragonwilds/Plugins/Developer/Sentry/Binaries/Linux/crashpad_handler 2>/dev/null || true

if [ -z "${OWNER_ID}" ]; then
    LogError "OWNER_ID is not set. The server cannot start without your RuneScape: DragonWilds Player ID."
    LogError "Find your Player ID in-game at the bottom of the Settings Menu."
    exit 1
fi

CONFIG_DIR="/home/steam/server-files/RSDragonwilds/Saved/Config/LinuxServer"
CONFIG_FILE="$CONFIG_DIR/DedicatedServer.ini"

mkdir -p "$CONFIG_DIR"
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
ServerGuid=
TEMPLATE
chown steam:steam "$CONFIG_FILE"

# shellcheck disable=SC2317
term_handler() {
    if ! shutdown_server; then
        kill -SIGTERM "$(pgrep -f RSDragonwilds)"
    fi
    tail --pid="$killpid" -f 2>/dev/null
}

trap 'term_handler' SIGTERM

# Start the server as steam user
su - steam -c "cd /home/steam/server && \
    DEFAULT_PORT='${DEFAULT_PORT}' \
    SERVER_NAME='${SERVER_NAME}' \
    DEFAULT_WORLD_NAME='${DEFAULT_WORLD_NAME}' \
    OWNER_ID='${OWNER_ID}' \
    ADMIN_PASSWORD='${ADMIN_PASSWORD}' \
    WORLD_PASSWORD='${WORLD_PASSWORD}' \
    MULTIHOME='${MULTIHOME}' \
    ./start.sh" &

killpid="$!"
wait "$killpid"
