#!/bin/bash

#================
# Log Definitions
#================
export LINE='\n'                        # Line Break
export RESET='\033[0m'                  # Text Reset
export WhiteText='\033[0;37m'           # White

# Bold
export RedBoldText='\033[1;31m'         # Red
export GreenBoldText='\033[1;32m'       # Green
export YellowBoldText='\033[1;33m'      # Yellow
export CyanBoldText='\033[1;36m'        # Cyan
#================
# End Log Definitions
#================

LogInfo() {
  Log "$1" "$WhiteText"
}
LogWarn() {
  Log "$1" "$YellowBoldText"
}
LogError() {
  Log "$1" "$RedBoldText"
}
LogSuccess() {
  Log "$1" "$GreenBoldText"
}
LogAction() {
  Log "$1" "$CyanBoldText" "====" "===="
}
Log() {
  local message="$1"
  local color="$2"
  local prefix="$3"
  local suffix="$4"
  printf "$color%s$RESET$LINE" "$prefix$message$suffix"
}

install() {
  LogAction "Starting server install"
  LogInfo "Installing RuneScape: DragonWilds Dedicated Server (App ID: 4019830)"

  if [ -z "${STEAM_USERNAME}" ] || [ -z "${STEAM_PASSWORD}" ]; then
    LogError "STEAM_USERNAME and STEAM_PASSWORD are required to download the dedicated server."
    exit 1
  fi

  /depotdownloader/DepotDownloader \
    -app 4019830 \
    -os linux \
    -dir /home/steam/server-files \
    -validate \
    -username "${STEAM_USERNAME}" \
    -password "${STEAM_PASSWORD}"
  LogSuccess "Server install complete"
}

# Attempt to shutdown the server gracefully
# Returns 0 if it is shutdown
# Returns 1 if it is not able to be shutdown
shutdown_server() {
  local return_val=0
  LogAction "Attempting graceful server shutdown"

  local pid
  pid=$(pgrep -f "RSDragonwilds")

  if [ -n "$pid" ]; then
    kill -SIGTERM "$pid"

    local count=0
    while [ $count -lt 30 ] && kill -0 "$pid" 2>/dev/null; do
      sleep 1
      count=$((count + 1))
    done

    if kill -0 "$pid" 2>/dev/null; then
      LogWarn "Server did not shutdown gracefully, forcing shutdown"
      return_val=1
    else
      LogSuccess "Server shutdown gracefully"
    fi
  else
    LogWarn "Server process not found"
    return_val=1
  fi

  return "$return_val"
}
