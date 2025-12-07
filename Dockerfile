# Multi-arch CS 1.6 Server Dockerfile
# Supports: linux/amd64, linux/arm64

ARG STEAMCMD_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"

# -----------------------------------------------------------
# Download HLDS on amd64 (works reliably)
# -----------------------------------------------------------
FROM --platform=linux/amd64 debian:bookworm-slim AS hlds-downloader

ARG STEAMCMD_URL

ENV DEBIAN_FRONTEND=noninteractive \
    HLDS_DIR=/opt/hlds \
    STEAMCMD_DIR=/opt/steamcmd

RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    lib32gcc-s1 \
    lib32stdc++6 \
    libc6:i386 \
    libstdc++6:i386 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p ${STEAMCMD_DIR} && \
    curl -sSL ${STEAMCMD_URL} | tar -xzC ${STEAMCMD_DIR}

RUN mkdir -p ${HLDS_DIR} && \
    ${STEAMCMD_DIR}/steamcmd.sh +force_install_dir ${HLDS_DIR} \
    +login anonymous \
    +app_set_config 90 mod cstrike \
    +app_update 90 validate \
    +app_update 90 -beta beta validate \
    +quit || true

RUN ${STEAMCMD_DIR}/steamcmd.sh +force_install_dir ${HLDS_DIR} \
    +login anonymous \
    +app_update 90 validate \
    +quit || true

# -----------------------------------------------------------
# x86_64 (amd64) runtime stage
# -----------------------------------------------------------
FROM debian:bookworm-slim AS runtime-amd64

ENV DEBIAN_FRONTEND=noninteractive \
    HLDS_DIR=/opt/hlds

RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    lib32gcc-s1 \
    lib32stdc++6 \
    libc6:i386 \
    libstdc++6:i386 \
    && rm -rf /var/lib/apt/lists/*

# Copy HLDS from downloader stage
COPY --from=hlds-downloader /opt/hlds ${HLDS_DIR}

# -----------------------------------------------------------
# ARM64 runtime stage - uses pre-built box86 for x86 emulation
# -----------------------------------------------------------
FROM debian:bookworm-slim AS runtime-arm64

ENV DEBIAN_FRONTEND=noninteractive \
    HLDS_DIR=/opt/hlds

# Install box86 from pre-built repository
# Source: https://github.com/ryanfortner/box86-debs
RUN dpkg --add-architecture armhf && \
    apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    libc6:armhf \
    libstdc++6:armhf \
    && curl -fsSL https://ryanfortner.github.io/box86-debs/box86.list -o /etc/apt/sources.list.d/box86.list \
    && curl -fsSL https://ryanfortner.github.io/box86-debs/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/box86-debs-archive-keyring.gpg \
    && apt-get update \
    && apt-get install -y --no-install-recommends box86-generic-arm:armhf \
    && rm -rf /var/lib/apt/lists/*

# Copy HLDS from downloader stage (cross-platform copy)
COPY --from=hlds-downloader /opt/hlds ${HLDS_DIR}

# -----------------------------------------------------------
# Final stage - select based on architecture
# -----------------------------------------------------------
FROM runtime-${TARGETARCH} AS final

ARG TARGETARCH

ENV HLDS_DIR=/opt/hlds

# Create non-root user for security
RUN useradd -m -d /home/steam steam && \
    chown -R steam:steam ${HLDS_DIR}

# Copy startup script
COPY --chmod=755 entrypoint.sh /entrypoint.sh

WORKDIR ${HLDS_DIR}

# Expose CS 1.6 server ports
EXPOSE 27015/udp
EXPOSE 27015/tcp

USER steam

ENTRYPOINT ["/entrypoint.sh"]
CMD ["+map", "de_dust2", "+maxplayers", "16"]
