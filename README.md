# CS 1.6 Docker Server (Multi-Architecture)

A Counter-Strike 1.6 dedicated server Docker image that runs on both **x86_64** and **ARM64** systems.

## Features

- Multi-architecture support (amd64 and arm64)
- ARM64 support via [box86](https://github.com/ptitSeb/box86) x86 emulation
- Configurable via environment variables
- RCON support for remote administration
- Custom map cycles and MOTD
- Lightweight Debian-based image

## Quick Start

```bash
docker compose up -d
```

Or with custom settings:

```bash
SERVER_NAME="My Server" SERVER_PASSWORD="secret" docker compose up -d
```

## Environment Variables

### Server Identity

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_NAME` | My CS 1.6 Server | Server hostname displayed in browser |
| `SERVER_PASSWORD` | *(empty)* | Password to join the server |
| `RCON_PASSWORD` | changeme | Remote console password |

### Server Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_PORT` | 27015 | Server port (UDP/TCP) |
| `MAX_PLAYERS` | 16 | Maximum players allowed |
| `START_MAP` | de_dust2 | Map loaded on server start |
| `SERVER_REGION` | 255 | Server region (255 = World) |

### Game Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `MP_TIMELIMIT` | 30 | Map time limit in minutes |
| `MP_ROUNDTIME` | 5 | Round time in minutes |
| `MP_FREEZETIME` | 6 | Freeze time at round start (seconds) |
| `MP_BUYTIME` | 90 | Buy time in seconds |
| `MP_C4TIMER` | 45 | C4 bomb timer in seconds |
| `MP_STARTMONEY` | 800 | Starting money |
| `MP_FRIENDLYFIRE` | 0 | Friendly fire (0=off, 1=on) |
| `MP_AUTOTEAMBALANCE` | 1 | Auto team balance (0=off, 1=on) |
| `MP_LIMITTEAMS` | 2 | Max team size difference |

### Server Performance

| Variable | Default | Description |
|----------|---------|-------------|
| `SYS_TICRATE` | 1000 | Server tick rate |
| `SV_MAXRATE` | 25000 | Maximum client rate |
| `SV_MINRATE` | 5000 | Minimum client rate |
| `SV_MAXUPDATERATE` | 102 | Maximum update rate |
| `SV_MINUPDATERATE` | 10 | Minimum update rate |
| `FPS_MAX` | 1000 | Maximum server FPS |

### Optional Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `MAPCYCLE` | *(empty)* | Comma-separated map list |
| `SERVER_MOTD` | *(empty)* | Message of the day |
| `SERVER_EXTRA_CFG` | *(empty)* | Additional config lines |

## Using a .env File

Create a `.env` file in the project directory:

```env
SERVER_NAME=My Private Server
SERVER_PASSWORD=secret123
RCON_PASSWORD=myadminpass
MAX_PLAYERS=20
START_MAP=de_inferno
MAPCYCLE=de_dust2,de_inferno,de_nuke,cs_assault,de_train
```

Then run:

```bash
docker compose up -d
```

## Building

### Build for current architecture

```bash
docker compose build
```

### Build for specific architecture

```bash
# AMD64
docker buildx build --platform linux/amd64 -t cs16-server:amd64 --load .

# ARM64
docker buildx build --platform linux/arm64 -t cs16-server:arm64 --load .
```

### Build multi-arch and push to registry

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t youruser/cs16-server:latest --push .
```

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 27015 | UDP | Game traffic |
| 27015 | TCP | RCON and queries |

Make sure these ports are open in your firewall for external access.

## RCON Usage

Connect to RCON using any Half-Life RCON client:

```
rcon_address your-server-ip:27015
rcon_password your-rcon-password
rcon status
```

## Browser Client Access

This server is compatible with browser-based CS 1.6 clients like [play-cs.com](https://play-cs.com). Ensure your server is publicly accessible on port 27015 (UDP/TCP).

## Architecture Details

- **AMD64**: Runs HLDS natively with i386 libraries
- **ARM64**: Uses box86 to emulate x86 binaries on ARM

The HLDS files are downloaded once during build on AMD64 and copied to both architecture images, ensuring consistent server files across platforms.

## License

This project provides Docker configuration for running CS 1.6 servers. Counter-Strike is a trademark of Valve Corporation.
