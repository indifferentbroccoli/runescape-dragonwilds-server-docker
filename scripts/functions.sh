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

# UE4SS needs the Windows build, names match Unreal's pak and Saved/Config folders
if [ "${UE4SS_ENABLED}" = "true" ]; then
  SERVER_PLATFORM="WindowsServer"
  OTHER_SERVER_PLATFORM="LinuxServer"
  DEPOT_OS="windows"
else
  SERVER_PLATFORM="LinuxServer"
  OTHER_SERVER_PLATFORM="WindowsServer"
  DEPOT_OS="linux"
fi

install() {
  LogAction "Starting server install"
  LogInfo "Installing RuneScape: DragonWilds Dedicated Server (${SERVER_PLATFORM})"

  # Unreal loads every pak in Content/Paks, so drop the other build's paks
  local paks_dir="/home/steam/server-files/RSDragonwilds/Content/Paks"
  if compgen -G "$paks_dir/RSDragonwilds-${OTHER_SERVER_PLATFORM}.*" > /dev/null; then
    LogWarn "Removing ${OTHER_SERVER_PLATFORM} content from the previous server build"
    rm -f "$paks_dir/RSDragonwilds-${OTHER_SERVER_PLATFORM}".{pak,ucas,utoc}
  fi

  /depotdownloader/DepotDownloader \
    -app 4019830 \
    -os "$DEPOT_OS" \
    -dir /home/steam/server-files \
    -validate

  LogSuccess "Server install complete"
}

# Installs or updates UE4SS to the latest experimental build, keeping settings and mods
install_ue4ss() {
  local win64_dir="/home/steam/server-files/RSDragonwilds/Binaries/Win64"

  # Wine never loads UE4SS's dwmapi.dll itself, so version.dll loads it
  mkdir -p "$win64_dir"
  cp -f /ue4ss/version.dll "$win64_dir/"

  LogAction "Installing UE4SS"

  local url
  url=$(curl -fsSL https://api.github.com/repos/UE4SS-RE/RE-UE4SS/releases/tags/experimental-latest |
    jq -r '[.assets[].browser_download_url | select(test("/UE4SS_v[^/]*\\.zip$"))] | first // empty')

  # Add missing files without overwriting settings or mods, then refresh the DLLs
  if [ -n "$url" ] && curl -fsSL "$url" -o /tmp/UE4SS.zip; then
    unzip -qn /tmp/UE4SS.zip -d "$win64_dir" &&
      unzip -qo /tmp/UE4SS.zip dwmapi.dll ue4ss/UE4SS.dll -d "$win64_dir"
    rm -f /tmp/UE4SS.zip
  else
    LogWarn "Could not download UE4SS, using the installed version"
  fi

  [ -f "$win64_dir/ue4ss/UE4SS.dll" ]
}

# Anchored to skip Wine's start.exe, which only has the path as an argument
server_pid() {
  pgrep -o -f "^[^ ]*RSDragonwildsServer-(Linux|Win64)-Shipping"
}

# Attempt to shutdown the server gracefully
# Returns 0 if it is shutdown
# Returns 1 if it is not able to be shutdown
shutdown_server() {
  local return_val=0
  LogAction "Attempting graceful server shutdown"

  local pid
  pid=$(server_pid)

  # Wine passes SIGINT on as Ctrl-C, which Unreal handles as a graceful exit
  local signal="SIGTERM"
  if [ "${UE4SS_ENABLED}" = "true" ]; then
    signal="SIGINT"
  fi

  if [ -n "$pid" ]; then
    kill -"$signal" "$pid"

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
