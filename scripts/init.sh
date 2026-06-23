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

# Preserve server-managed state across restarts. The whole ini is regenerated
# from the template below, so we carry over values the server owns:
#   - ServerGuid: the server's identity. If absent, leave it empty and let the
#     server generate one on first boot.
#   - KnownPlayerList: the player roster (privileges, bans). There can be many.
SERVER_GUID=""
KNOWN_PLAYERS=""
if [ -f "$CONFIG_FILE" ]; then
    SERVER_GUID=$(sed -n 's/^ServerGuid=//p' "$CONFIG_FILE" | head -n 1)
    KNOWN_PLAYERS=$(grep '^KnownPlayerList=' "$CONFIG_FILE" || true)
fi
export SERVER_GUID

if [ -n "$SERVER_GUID" ]; then
    LogInfo "Preserving existing ServerGuid: $SERVER_GUID"
else
    LogInfo "No existing ServerGuid found, server will generate one"
fi

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

# Append the preserved roster verbatim (not through envsubst, so usernames
# containing '$' or other special characters are kept intact). These belong to
# the [/Script/Dominion.DedicatedServerSettings] section, which is the last one
# in the file.
if [ -n "$KNOWN_PLAYERS" ]; then
    printf '%s\n' "$KNOWN_PLAYERS" >> "$CONFIG_FILE"
    player_count=$(printf '%s\n' "$KNOWN_PLAYERS" | grep -c '^KnownPlayerList=')
    LogInfo "Preserved $player_count known player(s)"
fi
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
    MAX_PLAYERS='${MAX_PLAYERS}' \
    MULTIHOME='${MULTIHOME}' \
    ./start.sh" &

killpid="$!"
wait "$killpid"
