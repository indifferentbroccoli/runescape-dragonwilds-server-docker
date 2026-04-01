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
    ./start.sh" &

killpid="$!"

# Write config after server has started and created the directory
CONFIG_DIR="/home/steam/server-files/RSDragonwilds/Saved/Config/LinuxServer"
CONFIG_FILE="$CONFIG_DIR/DedicatedServer.ini"
(
    sleep 10
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" <<EOF
[ServerSettings]
OwnerId=${OWNER_ID}
ServerName=${SERVER_NAME:-DragonWildsServer}
DefaultWorldName=${DEFAULT_WORLD_NAME:-MyWorld}
AdminPassword=${ADMIN_PASSWORD}
WorldPassword=${WORLD_PASSWORD}
Port=${DEFAULT_PORT:-7777}
EOF
) &
wait "$killpid"
