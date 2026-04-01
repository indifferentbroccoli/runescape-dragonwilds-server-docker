<!-- markdownlint-disable-next-line -->
![marketing_assets_banner](https://github.com/user-attachments/assets/b8b4ae5c-06bb-46a7-8d94-903a04595036)
[![GitHub License](https://img.shields.io/github/license/indifferentbroccoli/runscape-dragonwilds-server-docker?style=for-the-badge&color=6aa84f)](https://github.com/indifferentbroccoli/runscape-dragonwilds-server-docker/blob/main/LICENSE)
[![GitHub Release](https://img.shields.io/github/v/release/indifferentbroccoli/runscape-dragonwilds-server-docker?style=for-the-badge&color=6aa84f)](https://github.com/indifferentbroccoli/runscape-dragonwilds-server-docker/releases)
[![GitHub Repo stars](https://img.shields.io/github/stars/indifferentbroccoli/runscape-dragonwilds-server-docker?style=for-the-badge&color=6aa84f)](https://github.com/indifferentbroccoli/runscape-dragonwilds-server-docker)
[![Discord](https://img.shields.io/discord/798321161082896395?style=for-the-badge&label=Discord&labelColor=5865F2&color=6aa84f)](https://discord.gg/indifferentbroccoli)
[![Docker Pulls](https://img.shields.io/docker/pulls/indifferentbroccoli/runscape-dragonwilds-server-docker?style=for-the-badge&color=6aa84f)](https://hub.docker.com/r/indifferentbroccoli/runscape-dragonwilds-server-docker)

Game server hosting

Fast RAM, high-speed internet

Eat lag for breakfast

[Try our RuneScape: DragonWilds server hosting free for 2 days!](https://indifferentbroccoli.com/runescape-dragon-wilds-server-hosting)

## RuneScape: DragonWilds Dedicated Server Docker

A Docker container for running a RuneScape: DragonWilds dedicated server using DepotDownloader.

## Server Requirements

| Resource | Minimum       | Recommended |
|----------|---------------|-------------|
| CPU      | 4 cores       | 4+ cores    |
| RAM      | 8GB           | 16GB        |
| Storage  | 10GB          | 20GB        |

> [!NOTE]
> RAM required is 2GB + 1GB per player. For a full 6-player server you need 8GB.

## How to use

Copy the `.env.example` file to a new file called `.env`. Then use either `docker compose` or `docker run`.

### Docker Compose

```yaml
services:
  runescape-dragonwilds:
    image: indifferentbroccoli/runscape-dragonwilds-server-docker
    restart: unless-stopped
    container_name: runescape-dragonwilds
    stop_grace_period: 30s
    ports:
      - 7777:7777/udp
    env_file:
      - .env
    volumes:
      - ./server-files:/home/steam/server-files
```

Then run:

```bash
docker-compose up -d
```

### Docker Run

```bash
docker run -d \
    --restart unless-stopped \
    --name runescape-dragonwilds \
    --stop-timeout 30 \
    -p 7777:7777/udp \
    --env-file .env \
    -v ./server-files:/home/steam/server-files \
    indifferentbroccoli/runscape-dragonwilds-server-docker
```

## Environment Variables

| Variable           | Default            | Info                                                                                      |
|--------------------|--------------------|-------------------------------------------------------------------------------------------|
| PUID               | 1000               | User ID for file permissions                                                              |
| PGID               | 1000               | Group ID for file permissions                                                             |
| UPDATE_ON_START    | true               | If set to false, skips downloading and validating server files on startup                 |
| OWNER_ID           |                    | **Required.** Your RuneScape: DragonWilds Player ID (found in Settings Menu in-game)     |
| SERVER_NAME        | DragonWildsServer  | Display name of the server                                                                |
| DEFAULT_WORLD_NAME | MyWorld            | Name of the default world created on first startup                                        |
| ADMIN_PASSWORD     |                    | **Required.** Password to access Server Management in-game                               |
| WORLD_PASSWORD     |                    | Optional join password. Leave empty for a public server                                   |
| DEFAULT_PORT       | 7777               | The UDP port the server listens on                                                        |
| MAX_PLAYERS        | 6                  | Maximum number of players allowed on the server                                           |

> [!NOTE]
> If your server doesn't appear, check that UDP port 7777 is forwarded through your firewall/router and that `OWNER_ID` and `ADMIN_PASSWORD` are set.

## Port Forwarding

Forward **7777 UDP only**. Every router between you and your ISP will need port forwarding configured. See [portforward.com](https://portforward.com) for router-specific guides.

> [!IMPORTANT]
> The internal and external ports **must match**. If you change `DEFAULT_PORT`, update the port mapping in your compose file to match — e.g. `9000:9000/udp` with `DEFAULT_PORT=9000`. Mismatched ports will cause players to be kicked back to the title screen on join.

## User Management

Dedicated Servers divide users into three categories:

- **Owner** — the player whose Player ID matches `OWNER_ID` in config
- **Admin** — anyone who entered the `ADMIN_PASSWORD` in the Server Management screen
- **Regular users**

Owners can ban and unban anyone (online or offline). Admins can ban regular users who are online.

## Volumes

- `/home/steam/server-files` — Server installation files, saves, and configuration
