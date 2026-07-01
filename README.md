# OpenChamber Docker

![OpenChamber](https://img.shields.io/badge/OpenChamber-1.13.8-6366F1?logo=openchamber&logoColor=white) | ![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker&logoColor=white) | ![License](https://img.shields.io/github/license/dipievil/openchamber-docker) | ![Drone](https://img.shields.io/badge/Drone-CI-0EABE5?logo=drone&logoColor=white)

A fully configurable [Docker](https://www.docker.com/) image for [OpenChamber](https://openchamber.dev/), the agentic development environment for AI coding, powered by [OpenCode](https://opencode.ai/). Built daily from the upstream source and published to Docker Hub automatically via Drone CI.

## Table of Contents

- [OpenChamber Docker](#openchamber-docker)
  - [Table of Contents](#table-of-contents)
  - [About](#about)
    - [Features](#features)
  - [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
  - [Usage](#usage)
    - [Quick Start](#quick-start)
    - [Docker Compose](#docker-compose)
    - [Configuration](#configuration)
      - [Using .env File](#using-env-file)
      - [Building a Specific Version](#building-a-specific-version)
      - [External OpenCode Server](#external-opencode-server)
  - [Environment Variables](#environment-variables)
  - [Volumes](#volumes)
  - [Makefile Commands](#makefile-commands)
  - [Troubleshooting](#troubleshooting)
    - [Container starts but page doesn't load at `http://localhost:3000`](#container-starts-but-page-doesnt-load-at-httplocalhost3000)
    - ["Connection refused" when accessing the web UI](#connection-refused-when-accessing-the-web-ui)
    - [Permission errors with mounted volumes](#permission-errors-with-mounted-volumes)
  - [Contributing](#contributing)
    - [Reporting Issues](#reporting-issues)
  - [License](#license)
  - [Acknowledgements](#acknowledgements)

## About

**openchamber-docker** packages [OpenChamber](https://github.com/openchamber/openchamber) — the open-source web UI for OpenCode AI agents — into a production-ready Docker image. The image is built multi-stage from the upstream source, bundling all runtime dependencies (Node.js, Git, SSH, OpenCode CLI) so you can deploy OpenChamber anywhere with a single command.

The image is automatically rebuilt and published to Docker Hub every day. When a new OpenChamber version is detected, it builds and pushes both the version-specific tag and `latest`.

### Features

- **Fully Configurable**: All OpenChamber and OpenCode settings exposed as environment variables
- **Persistent Workspaces**: Mount volumes for config, workspaces, SSH keys, and OpenCode state
- **Auto-generated SSH Keys**: SSH keypair created on first start if none exists
- **Daily Updates**: Smart Drone CI pipeline builds only when a new version is published upstream
- **Semantic Release**: Automatic CHANGELOG generation and GitHub releases

## Getting Started

### Prerequisites

- [Docker](https://docs.docker.com/engine/install/) 24+
- [Docker Compose](https://docs.docker.com/compose/install/) v2+

## Usage

### Quick Start

```bash
# Pull from Docker Hub
docker pull dipi/openchamber:latest

# Run with a UI password
docker run -d \
  -p 3000:3000 \
  -e OPENCHAMBER_UI_PASSWORD="your-strong-password" \
  -v ./workspaces:/home/openchamber/workspaces \
  dipi/openchamber:latest
```

Open `http://localhost:3000` in your browser.

### Docker Compose

Create a `docker-compose.yml`:

```yaml
services:
  openchamber:
    image: dipi/openchamber:latest
    container_name: openchamber
    ports:
      - "3000:3000"
    extra_hosts:
      - "host.docker.internal:host-gateway"
    volumes:
      - ./data/openchamber:/home/openchamber/.config/openchamber
      - ./data/opencode/share:/home/openchamber/.local/share/opencode
      - ./data/opencode/state:/home/openchamber/.local/state/opencode
      - ./data/opencode/config:/home/openchamber/.config/opencode
      - ./data/ssh:/home/openchamber/.ssh
      - ./workspaces:/home/openchamber/workspaces
    restart: unless-stopped
```

All configuration is done through a `.env` file (see below). Docker Compose loads it automatically.

Start with:

```bash
cp .env.example .env
# Edit .env and set OPENCHAMBER_UI_PASSWORD
docker compose up -d
```

### Configuration

#### Using .env File

Copy the provided `.env.example` to `.env` and edit:

```bash
cp .env.example .env
```

Example `.env`:

```dotenv
# Required
OPENCHAMBER_UI_PASSWORD=your-strong-password

# Optional: bind to all interfaces
OPENCHAMBER_HOST=0.0.0.0
```

Docker Compose reads the `.env` file automatically — no need to pass it explicitly. All variables are documented in [Environment Variables](#environment-variables) below.

#### Building a Specific Version

```bash
# Build a specific OpenChamber version locally
make build VERSION=v1.13.8

# Or with Docker directly
docker build \
  --build-arg OPENCHAMBER_VERSION=v1.13.8 \
  -t dipi/openchamber:custom \
  -f docker/Dockerfile .
```

#### External OpenCode Server

Add to your `.env`:

```dotenv
OPENCODE_HOST=http://host.docker.internal:4096
OPENCODE_SKIP_START=true
```

## Environment Variables

All configuration is done through environment variables. The entrypoint handles each automatically.

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `OPENCHAMBER_UI_PASSWORD` | No | — | Web UI password for authentication |
| `UI_PASSWORD` | No | — | Legacy alias for `OPENCHAMBER_UI_PASSWORD` |
| `OPENCHAMBER_HOST` | No | `0.0.0.0` | Bind address (Docker entrypoint default) |
| `OPENCODE_HOST` | No | — | Connect to an external OpenCode server |
| `OPENCODE_SKIP_START` | No | `false` | Skip starting the bundled OpenCode process |
| `OPENCHAMBER_OPENCODE_HOSTNAME` | No | `127.0.0.1` | OpenCode bind address |

## Volumes

Persistent data directories to mount for stateful operation:

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `./data/openchamber` | `/home/openchamber/.config/openchamber` | OpenChamber configuration files |
| `./data/opencode/share` | `/home/openchamber/.local/share/opencode` | OpenCode shared data (models, cache) |
| `./data/opencode/state` | `/home/openchamber/.local/state/opencode` | OpenCode runtime state |
| `./data/opencode/config` | `/home/openchamber/.config/opencode` | OpenCode configuration |
| `./data/ssh` | `/home/openchamber/.ssh` | SSH keys (auto-generated if missing) |
| `./workspaces` | `/home/openchamber/workspaces` | User project workspaces |

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make build VERSION=v1.13.8` | Build Docker image with optional version |
| `make run` | Start container with `docker compose up -d` |
| `make test VERSION=v1.13.8` | Build and verify the container starts |
| `make clean` | Stop compose and remove local image |
| `make version` | Fetch latest OpenChamber release tag from GitHub |

## Troubleshooting

### Container starts but page doesn't load at `http://localhost:3000`

**Solutions:**
- Wait a few seconds for OpenChamber to initialize and start OpenCode
- Check container logs: `docker logs openchamber`
- Verify the container is running: `docker ps`

### "Connection refused" when accessing the web UI

**Solutions:**
- Ensure `OPENCHAMBER_HOST` is set to `0.0.0.0` (the Docker default in the entrypoint)
- Check port mapping: `docker ps` should show `0.0.0.0:3000->3000/tcp`
- On macOS/Windows, use `localhost` instead of `127.0.0.1`

### Permission errors with mounted volumes

**Solutions:**
- The container runs as UID 1000 (`openchamber`). Ensure mounted directories are owned by UID 1000 on the host:
  ```bash
  sudo chown -R 1000:1000 ./data ./workspaces
  ```
- Or pre-create the directories before starting the container

## Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork the repository** and create a feature branch
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** and ensure the Dockerfile builds
   ```bash
   make build
   ```

3. **Follow conventional commits** for commit messages
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation
   - `chore:` for maintenance

4. **Create a pull request** with a clear description of your changes

### Reporting Issues

Please report issues with:
- Clear title describing the problem
- Steps to reproduce
- Expected vs actual behavior
- Docker version (`docker version`) and platform
- Container logs: `docker logs openchamber --tail=100`

## License

This project is licensed under the **Apache License 2.0**. See [LICENSE](LICENSE) file for details.

## Acknowledgements

- [OpenChamber](https://openchamber.dev/) — Agentic development environment for AI coding
- [OpenCode](https://opencode.ai/) — AI coding agent SDK
- [Drone CI](https://www.drone.io/) — Continuous integration platform
- [semantic-release](https://semantic-release.gitbook.io/) — Automated version management

---

**Questions or Issues?** [Create an issue](https://github.com/dipievil/openchamber-docker/issues) on GitHub!
