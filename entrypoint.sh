#!/bin/bash
set -e

HLDS_DIR="/opt/hlds"
ARCH=$(uname -m)

# Default server parameters
SERVER_PORT="${SERVER_PORT:-27015}"

# Verify HLDS installation
verify_hlds() {
    if [ ! -d "${HLDS_DIR}/cstrike" ]; then
        echo "ERROR: HLDS cstrike directory not found at ${HLDS_DIR}/cstrike"
        echo "The game files may not have been properly installed during build."
        echo "Contents of ${HLDS_DIR}:"
        ls -la "${HLDS_DIR}" 2>/dev/null || echo "  (directory does not exist)"
        exit 1
    fi

    if [ ! -f "${HLDS_DIR}/hlds_run" ]; then
        echo "ERROR: hlds_run not found at ${HLDS_DIR}/hlds_run"
        exit 1
    fi
}

# Generate server.cfg from environment variables
generate_server_cfg() {
    local cfg_file="${HLDS_DIR}/cstrike/server.cfg"

    cat > "${cfg_file}" << EOF
// CS 1.6 Server Configuration
// Generated from environment variables

// Server Identity
hostname "${SERVER_NAME:-Counter-Strike 1.6 Server}"
sv_password "${SERVER_PASSWORD:-}"
rcon_password "${RCON_PASSWORD:-}"

// Network Settings
sv_lan 0
sv_region ${SERVER_REGION:-255}

// Game Settings
mp_timelimit ${MP_TIMELIMIT:-30}
mp_roundtime ${MP_ROUNDTIME:-5}
mp_freezetime ${MP_FREEZETIME:-6}
mp_buytime ${MP_BUYTIME:-90}
mp_c4timer ${MP_C4TIMER:-45}
mp_startmoney ${MP_STARTMONEY:-800}
mp_friendlyfire ${MP_FRIENDLYFIRE:-0}
mp_autoteambalance ${MP_AUTOTEAMBALANCE:-1}
mp_limitteams ${MP_LIMITTEAMS:-2}
mp_tkpunish ${MP_TKPUNISH:-0}
mp_autokick ${MP_AUTOKICK:-1}
mp_hostagepenalty ${MP_HOSTAGEPENALTY:-5}

// Server Performance
sys_ticrate ${SYS_TICRATE:-1000}
sv_maxrate ${SV_MAXRATE:-25000}
sv_minrate ${SV_MINRATE:-5000}
sv_maxupdaterate ${SV_MAXUPDATERATE:-102}
sv_minupdaterate ${SV_MINUPDATERATE:-10}
fps_max ${FPS_MAX:-1000}

// Anti-Cheat
sv_cheats 0

// Logging
log on
sv_logbans 1
sv_logecho 1
sv_logfile 1
sv_log_onefile 0

// Additional custom config
${SERVER_EXTRA_CFG:-}
EOF

    echo "Generated server.cfg"
}

# Generate mapcycle.txt if custom maps provided
generate_mapcycle() {
    local mapcycle_file="${HLDS_DIR}/cstrike/mapcycle.txt"

    if [ -n "${MAPCYCLE:-}" ]; then
        echo "${MAPCYCLE}" | tr ',' '\n' > "${mapcycle_file}"
        echo "Generated custom mapcycle.txt"
    fi
}

# Generate motd.txt if provided
generate_motd() {
    local motd_file="${HLDS_DIR}/cstrike/motd.txt"

    if [ -n "${SERVER_MOTD:-}" ]; then
        echo "${SERVER_MOTD}" > "${motd_file}"
        echo "Generated motd.txt"
    fi
}

# Main setup
cd "${HLDS_DIR}"

verify_hlds
generate_server_cfg
generate_mapcycle
generate_motd

# Build command line arguments
HLDS_ARGS="-game cstrike -port ${SERVER_PORT} -pingboost 3 +sys_ticrate ${SYS_TICRATE:-1000}"

# Add map
HLDS_ARGS="${HLDS_ARGS} +map ${START_MAP:-de_dust2}"

# Add maxplayers
HLDS_ARGS="${HLDS_ARGS} +maxplayers ${MAX_PLAYERS:-16}"

# Add any extra arguments passed to the container
HLDS_ARGS="${HLDS_ARGS} $@"

echo "============================================"
echo "  CS 1.6 Server Starting"
echo "============================================"
echo "  Hostname: ${SERVER_NAME:-Counter-Strike 1.6 Server}"
echo "  Port: ${SERVER_PORT}"
echo "  Max Players: ${MAX_PLAYERS:-16}"
echo "  Start Map: ${START_MAP:-de_dust2}"
echo "  Password: ${SERVER_PASSWORD:+[SET]}"
echo "  RCON: ${RCON_PASSWORD:+[SET]}"
echo "============================================"

# Run the server based on architecture
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    echo "Platform: ARM64 (using box86)"

    # Create wrapper to run hlds_linux through box86
    # hlds_run is a shell script that calls ./hlds_linux
    # We need to intercept that call with box86
    if [ ! -f "${HLDS_DIR}/hlds_linux.real" ]; then
        mv "${HLDS_DIR}/hlds_linux" "${HLDS_DIR}/hlds_linux.real"
        cat > "${HLDS_DIR}/hlds_linux" << 'WRAPPER'
#!/bin/bash
exec box86 "$(dirname "$0")/hlds_linux.real" "$@"
WRAPPER
        chmod +x "${HLDS_DIR}/hlds_linux"
    fi

    exec ./hlds_run ${HLDS_ARGS}
else
    echo "Platform: x86_64"
    exec ./hlds_run ${HLDS_ARGS}
fi
