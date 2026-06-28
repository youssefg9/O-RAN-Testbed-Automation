#!/bin/bash
#
# Starts the full O-RAN testbed: Core → FlexRIC → gNB → UE(s) → xApp (foreground)
# Press Ctrl+C to stop everything gracefully.
#
# Configuration is read from testbed_config.json. CLI args override config values.
#
# Usage:
#   ./run.sh                                # Use testbed_config.json defaults
#   ./run.sh 3                              # Override: 3 UEs
#   ./run.sh --grafana                      # Override: enable Grafana
#   ./run.sh --no-xapp                      # Override: no xApp
#   ./run.sh --gnb oai                      # Override: use OAI gNB
#   ./run.sh --config my.json               # Use a different config file
#   ./run.sh 3 --grafana --gnb oai          # Combine overrides

set -e

SCRIPT_DIR=$(dirname "$(realpath "$0")")
cd "$SCRIPT_DIR"

# ── Parse CLI args (overrides for config) ─────────────────────────────────────
CLI_NUM_UES=""
CLI_GRAFANA=""
CLI_XAPP=""
CLI_GNB_TYPE=""
CLI_UE_TYPE=""
CLI_RIC_ENABLED=""
CONFIG_FILE="testbed_config.json"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --config)    CONFIG_FILE="$2"; shift 2 ;;
        --grafana)   CLI_GRAFANA=true; shift ;;
        --no-xapp)   CLI_XAPP=none; shift ;;
        --no-ric)    CLI_RIC_ENABLED=false; shift ;;
        --gnb)       CLI_GNB_TYPE="$2"; shift 2 ;;
        --ue)        CLI_UE_TYPE="$2"; shift 2 ;;
        *)
            if [[ "$1" =~ ^[0-9]+$ ]]; then
                CLI_NUM_UES="$1"
            else
                echo "Unknown argument: $1"
                echo "Usage: $0 [NUM_UES] [--config FILE] [--grafana] [--no-xapp] [--no-ric]"
                echo "       [--gnb srsran|oai] [--ue srsran|oai]"
                exit 1
            fi
            shift ;;
    esac
done

# ── Load config ──────────────────────────────────────────────────────────────
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Config file not found: $CONFIG_FILE"
    echo "Create one with: cp testbed_config.json.example testbed_config.json"
    exit 1
fi

cfg() { jq -r "$1 | if . == null then empty else . end" "$CONFIG_FILE" 2>/dev/null; }

# Read config values (with defaults)
GNB_TYPE="${CLI_GNB_TYPE:-$(cfg '.gnb.type')}"
GNB_TYPE="${GNB_TYPE:-srsran}"

UE_TYPE="${CLI_UE_TYPE:-$(cfg '.ue.type')}"
# Default UE type matches gNB type
UE_TYPE="${UE_TYPE:-$GNB_TYPE}"

NUM_UES="${CLI_NUM_UES:-$(cfg '.ue.num_ues')}"
NUM_UES="${NUM_UES:-1}"

RIC_ENABLED="${CLI_RIC_ENABLED:-$(cfg '.ric.enabled')}"
RIC_ENABLED="${RIC_ENABLED:-true}"

XAPP_NAME="$(cfg '.ric.xapp')"
XAPP_NAME="${XAPP_NAME:-kpm_moni}"

USE_GRAFANA="${CLI_GRAFANA:-$(cfg '.grafana.enabled')}"
USE_GRAFANA="${USE_GRAFANA:-false}"

CSV_PERIODICITY="$(cfg '.grafana.csv_periodicity_ms')"
CSV_PERIODICITY="${CSV_PERIODICITY:-1000}"

GRAFANA_URL="$(cfg '.grafana.url')"
if [[ -z "$GRAFANA_URL" ]]; then
    if [[ "$GNB_TYPE" == "oai" ]]; then
        # OAI/FlexRIC dashboards are served by host Grafana.
        GRAFANA_URL="$(cfg '.grafana.flexric_url')"
        GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000/dashboards}"
    else
        # srs/OCUDU metrics Grafana runs in Docker and is exposed on 3300.
        GRAFANA_URL="$(cfg '.grafana.ocudu_url')"
        GRAFANA_URL="${GRAFANA_URL:-http://localhost:3300}"
    fi
fi

# CLI --no-xapp overrides config
if [[ "$CLI_XAPP" == "none" ]]; then
    XAPP_NAME="none"
fi
# --grafana implies xapp is csv
if [[ "$USE_GRAFANA" == "true" && "$XAPP_NAME" != "none" ]]; then
    XAPP_NAME="kpm_moni_csv"
fi

# ── Resolve paths based on gNB/UE type ───────────────────────────────────────
if [[ "$GNB_TYPE" == "oai" ]]; then
    GNB_DIR="OpenAirInterface_Testbed/Next_Generation_Node_B"
    GNB_PROCESS="nr-softmodem"
    GNB_READY_PATTERN="TYPE <CTRL-C> TO TERMINATE"
    RIC_DIR="OpenAirInterface_Testbed/RAN_Intelligent_Controllers/Flexible-RIC"
    STOP_SCRIPT="stop.sh"
else
    GNB_DIR="Next_Generation_Node_B"
    GNB_PROCESS="gnb"
    GNB_READY_PATTERN="==== gNodeB started"
    RIC_DIR="RAN_Intelligent_Controllers/Flexible-RIC"
    STOP_SCRIPT="stop.sh"
fi

if [[ "$UE_TYPE" == "oai" ]]; then
    UE_DIR="OpenAirInterface_Testbed/User_Equipment"
    UE_PROCESS="nr-uesoftmodem"
    UE_READY_PATTERN="TYPE <CTRL-C> TO TERMINATE"
else
    UE_DIR="User_Equipment"
    UE_PROCESS="srsue"
    UE_READY_PATTERN=""
fi

CORE_DIR="5G_Core_Network"
# OAI testbed uses a symlinked 5G_Core_Network
if [[ "$GNB_TYPE" == "oai" && -d "OpenAirInterface_Testbed/5G_Core_Network" ]]; then
    CORE_DIR="OpenAirInterface_Testbed/5G_Core_Network"
fi

# ── Print configuration ─────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════════════════════"
echo "  O-RAN Testbed Configuration"
echo "═══════════════════════════════════════════════════════════════════════════"
echo "  Config file : $CONFIG_FILE"
echo "  gNB type    : $GNB_TYPE"
echo "  UE type     : $UE_TYPE ($NUM_UES UEs)"
echo "  RIC         : $( [[ $RIC_ENABLED == true ]] && echo 'enabled' || echo 'disabled' )"
echo "  xApp        : $XAPP_NAME"
echo "  Grafana     : $USE_GRAFANA"
if [[ "$USE_GRAFANA" == "true" ]]; then
    echo "  Grafana URL : $GRAFANA_URL"
fi
echo "═══════════════════════════════════════════════════════════════════════════"
echo

sudo -v

# Keep component logs bounded without changing the component PID.
start_log_limiter() {
    local target_pid="$1"
    local log_file="$2"
    local max_bytes=$((50 * 1024 * 1024))
    local keep_bytes=$((25 * 1024 * 1024))

    (
        while kill -0 "$target_pid" 2>/dev/null; do
            if [[ -f "$log_file" ]]; then
                local size
                size=$(stat -c%s "$log_file" 2>/dev/null || echo 0)
                if [[ "$size" -gt "$max_bytes" ]]; then
                    tail -c "$keep_bytes" "$log_file" > "${log_file}.tmp" 2>/dev/null && mv "${log_file}.tmp" "$log_file"
                fi
            fi
            sleep 5
        done
    ) >/dev/null 2>&1 &
}

is_ocudu_broker_running() {
    pgrep -f "[p]ython3 .*zmq_broker/multi_ue_scenario(_custom)?\.py" >/dev/null
}

cleanup_stale_docker_bridges() {
    local iface
    local found_stale=false

    # Remove stale Docker bridge interfaces that still have linkdown routes.
    # These stale bridges can hijack routing to active container subnets.
    while IFS= read -r iface; do
        [[ -z "$iface" ]] && continue
        found_stale=true
        echo "Removing stale Docker bridge interface: $iface"
        sudo ip link delete "$iface" >/dev/null 2>&1 || true
    done < <(ip -o route 2>/dev/null | awk '/ dev br-[a-f0-9]+ / && /linkdown/ { for (i=1; i<=NF; i++) if ($i == "dev") print $(i+1) }' | sort -u)

    if [[ "$found_stale" == true ]]; then
        # Refresh docker-proxy/network state after bridge cleanup.
        sudo systemctl restart docker >/dev/null 2>&1 || true
    fi
}

check_ocudu_zmq_ports_conflicts() {
    local listeners

    # Only needed for the srs/OCUDU path that uses GNU Radio ZMQ ports 2000/2001.
    if [[ "$GNB_TYPE" == "oai" ]]; then
        return 0
    fi

    if command -v ss >/dev/null 2>&1; then
        listeners=$(sudo ss -H -ltnp 2>/dev/null | awk '$4 ~ /:2000$|:2001$/' || true)
    else
        listeners=""
    fi

    if [[ -n "$listeners" ]]; then
        # If the only listeners are our own gnb / broker from a previous run,
        # kill them automatically so the user does not have to intervene.
        local stale_pids
        stale_pids=$(echo "$listeners" | grep -oP 'pid=\K[0-9]+' | sort -u)
        local all_ours=true
        for pid in $stale_pids; do
            local pname
            pname=$(ps -p "$pid" -o comm= 2>/dev/null || true)
            if [[ "$pname" != "gnb" && "$pname" != "python3" && "$pname" != "python" ]]; then
                all_ours=false
                break
            fi
        done

        if $all_ours && [[ -n "$stale_pids" ]]; then
            echo "Cleaning up stale gNB/broker processes on ZMQ ports 2000/2001..."
            for pid in $stale_pids; do
                sudo kill "$pid" 2>/dev/null || true
            done
            sleep 1
            # Verify ports are free now
            local recheck
            recheck=$(sudo ss -H -ltnp 2>/dev/null | awk '$4 ~ /:2000$|:2001$/' || true)
            if [[ -n "$recheck" ]]; then
                echo "Error: Could not free ZMQ ports after killing stale processes."
                echo "$recheck"
                return 1
            fi
            echo "Stale processes cleaned up successfully."
        else
            echo "Error: OCUDU ZMQ ports are already in use (tcp://127.0.0.1:2000 or :2001)."
            echo "This blocks gNodeB/broker startup. Stop the conflicting process and rerun ./run.sh."
            echo
            echo "$listeners"
            echo
            echo "Hint: ss -ltnp | grep -E ':2000|:2001'"
            return 1
        fi
    fi
}

# On exit (Ctrl+C or error), stop everything
trap 'trap - EXIT SIGINT SIGTERM; echo; echo "##############################  STOPPING...  ##############################"; cd "$SCRIPT_DIR"; "$SCRIPT_DIR/$STOP_SCRIPT"; stty sane || true; exit' EXIT SIGINT SIGTERM

cleanup_stale_docker_bridges
check_ocudu_zmq_ports_conflicts

# ── 1. Core ──────────────────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════════════════════"
echo "  Starting 5G Core (Open5GS)..."
echo "═══════════════════════════════════════════════════════════════════════════"
cd "$CORE_DIR"
./run.sh
cd "$SCRIPT_DIR"

echo -n "Waiting for AMF to be ready"
attempt=0
AMF_CHECK="$CORE_DIR/is_amf_ready.sh"
# Fallback: OAI testbed may use parent's is_amf_ready.sh
[[ ! -f "$AMF_CHECK" ]] && AMF_CHECK="5G_Core_Network/is_amf_ready.sh"
while ! "$AMF_CHECK" 2>/dev/null | grep -q "true"; do
    echo -n "."
    sleep 0.5
    attempt=$((attempt + 1))
    if [[ $attempt -ge 120 ]]; then
        echo -e "\nAMF did not start after 60 seconds, exiting..."
        exit 1
    fi
done
echo -e "\nAMF is ready."

# ── 2. FlexRIC nearRT-RIC ───────────────────────────────────────────────────
if [[ "$RIC_ENABLED" == "true" ]]; then
    echo
    echo "═══════════════════════════════════════════════════════════════════════════"
    echo "  Starting FlexRIC nearRT-RIC..."
    echo "═══════════════════════════════════════════════════════════════════════════"
    cd "$RIC_DIR"
    ./run_background.sh
    if ./is_running.sh | grep -q "NOT_RUNNING"; then
        echo "Error starting FlexRIC. Check logs/flexric_stdout.txt"
        exit 1
    fi
    cd "$SCRIPT_DIR"
fi

# ── 3. gNodeB ─────────────────────────────────────────────────────────────────
echo
echo "═══════════════════════════════════════════════════════════════════════════"
echo "  Starting gNodeB ($GNB_TYPE)..."
echo "═══════════════════════════════════════════════════════════════════════════"

cd "$GNB_DIR"
# Kill any stale ZMQ broker from a previous run before starting gNB.
# The gNB's run.sh will start a fresh broker before the gNB binary,
# ensuring the REQ/REP handshake between gNB and broker succeeds.
if pgrep -f "[p]ython3 .*zmq_broker/multi_ue_scenario(_custom)?\.py" >/dev/null; then
    echo "  Stopping stale ZMQ Broker..."
    pkill -f "[p]ython3 .*zmq_broker/multi_ue_scenario(_custom)?\.py" || true
    sleep 1
fi
NUM_UES="$NUM_UES" ./run_background.sh
cd "$SCRIPT_DIR"

echo -n "Waiting for gNodeB to be ready"
attempt=0
while true; do
    if [[ -f "$GNB_DIR/logs/gnb_stdout.txt" ]] && \
       grep -q "$GNB_READY_PATTERN" "$GNB_DIR/logs/gnb_stdout.txt" 2>/dev/null; then
        break
    fi
    if [[ $attempt -ge 10 ]] && pgrep -x "$GNB_PROCESS" >/dev/null 2>&1; then
        break
    fi
    echo -n "."
    sleep 0.5
    attempt=$((attempt + 1))
    if [[ $attempt -ge 120 ]]; then
        if pgrep -x "$GNB_PROCESS" >/dev/null 2>&1; then
            break
        fi
        echo -e "\ngNodeB did not start after 60 seconds, exiting..."
        exit 1
    fi
done
echo -e "\ngNodeB is running."

# ── 3b. OCUDU Metrics (srsRAN only) ──────────────────────────────────────────
if [[ "$GNB_TYPE" != "oai" ]]; then
    echo
    echo "═══════════════════════════════════════════════════════════════════════════"
    echo "  Starting OCUDU Metrics (Telegraf + InfluxDB + Grafana)..."
    echo "═══════════════════════════════════════════════════════════════════════════"
    cd "$GNB_DIR"
    ./start_grafana_webui.sh || echo "Warning: OCUDU metrics failed to start (non-fatal)"
    cd "$SCRIPT_DIR"
fi

# ── 4. User Equipment ────────────────────────────────────────────────────────
echo
echo "═══════════════════════════════════════════════════════════════════════════"
echo "  Starting $NUM_UES UE(s) ($UE_TYPE)..."
echo "═══════════════════════════════════════════════════════════════════════════"

if [[ "$GNB_TYPE" != "oai" && "$NUM_UES" -gt 0 ]]; then
    # Broker is already running (started by gNB's run.sh before the gNB binary).
    # Start the configured UE set first, then wait for PDU sessions. The
    # multi-UE GNU Radio broker has one UL source per UE; waiting 30 s for UE1
    # before UE2/UE3 exist can starve the graph and causes Msg3 CRC failures.
    cd "$SCRIPT_DIR/$UE_DIR"
    for i in $(seq 1 "$NUM_UES"); do
        ./run_background.sh "$i"
        sleep 1
    done

    # Wait for all UEs to complete RRC + PDU session (up to 90 s).
    for attempt in $(seq 1 180); do
        connected_ues=0
        for i in $(seq 1 "$NUM_UES"); do
            if grep -q "PDU Session Establishment successful" \
                    "logs/ue${i}_stdout.txt" 2>/dev/null; then
                connected_ues=$((connected_ues + 1))
            fi
        done
        if [[ "$connected_ues" -eq "$NUM_UES" ]]; then
            echo "  All $NUM_UES UE(s) connected."
            break
        fi
        sleep 0.5
    done
    if [[ "$connected_ues" -lt "$NUM_UES" ]]; then
        echo "  Warning: only $connected_ues/$NUM_UES UE(s) completed PDU session in 90 s — continuing."
        for i in $(seq 1 "$NUM_UES"); do
            if grep -q "PDU Session Establishment successful" \
                    "logs/ue${i}_stdout.txt" 2>/dev/null; then
                echo "  UE $i connected."
            else
                echo "  UE $i not connected."
            fi
        done
    fi
    cd "$SCRIPT_DIR"
else
    # ── OAI UE: no broker needed ─────────────────────────────────────────────
    cd "$SCRIPT_DIR/$UE_DIR"
    for i in $(seq 1 "$NUM_UES"); do
        ./run_background.sh "$i"
    done
    cd "$SCRIPT_DIR"
fi

# Wait for first UE to connect (OAI has specific ready patterns)
if [[ -n "$UE_READY_PATTERN" ]]; then
    echo -n "Waiting for UE to be ready"
    attempt=0
    while true; do
        if [[ -f "$SCRIPT_DIR/$UE_DIR/logs/ue1_stdout.txt" ]]; then
            if grep -q "$UE_READY_PATTERN" "$SCRIPT_DIR/$UE_DIR/logs/ue1_stdout.txt" 2>/dev/null; then
                break
            fi
            if grep -q "State = NR_RRC_CONNECTED" "$SCRIPT_DIR/$UE_DIR/logs/ue1_stdout.txt" 2>/dev/null; then
                break
            fi
        fi
        echo -n "."
        sleep 0.5
        attempt=$((attempt + 1))
        if [[ $attempt -ge 120 ]]; then
            if pgrep -x "$UE_PROCESS" >/dev/null 2>&1; then
                break
            fi
            echo -e "\nUE did not start after 60 seconds, exiting..."
            exit 1
        fi
    done
    echo -e "\nUE is ready."
fi

# ── 5. Status ─────────────────────────────────────────────────────────────────
echo
echo "═══════════════════════════════════════════════════════════════════════════"
echo "  All components started. Status:"
echo "═══════════════════════════════════════════════════════════════════════════"
echo
"$CORE_DIR/is_running.sh" 2>/dev/null | head -3 || true
if [[ "$RIC_ENABLED" == "true" ]]; then
    echo "  FlexRIC:  $("$RIC_DIR/is_running.sh" 2>/dev/null | grep -oE 'RUNNING|NOT_RUNNING' | head -1)"
fi
"$GNB_DIR/is_running.sh" 2>/dev/null || true
"$UE_DIR/is_running.sh" 2>/dev/null || true
echo

# ── 6. xApp (foreground) ─────────────────────────────────────────────────────
case "$XAPP_NAME" in
    kpm_moni_csv|kpm_csv)
        echo "═══════════════════════════════════════════════════════════════════════════"
        echo "  Starting Grafana Dashboard + CSV KPM xApp (foreground)..."
        echo "  Grafana: $GRAFANA_URL  (admin/admin)"
        echo "  Press Ctrl+C to stop all components."
        echo "═══════════════════════════════════════════════════════════════════════════"
        echo
        cd "$RIC_DIR"
        if [[ "$USE_GRAFANA" == "true" ]]; then
            GRAFANA_URL="$GRAFANA_URL" ./additional_scripts/start_grafana_with_csv_xapp_kpm_moni.sh
        else
            ./additional_scripts/run_xapp_kpm_moni_write_to_csv.sh "$CSV_PERIODICITY"
        fi
        cd "$SCRIPT_DIR"
        ;;
    kpm_moni|kpm)
        echo "═══════════════════════════════════════════════════════════════════════════"
        echo "  Starting KPM Monitor xApp (foreground)..."
        echo "  Press Ctrl+C to stop all components."
        echo "═══════════════════════════════════════════════════════════════════════════"
        echo
        cd "$RIC_DIR"
        ./run_xapp_kpm_moni.sh
        cd "$SCRIPT_DIR"
        ;;
    gtp_mac_rlc_pdcp_moni|custom_sm)
        echo "═══════════════════════════════════════════════════════════════════════════"
        echo "  Starting GTP/MAC/RLC/PDCP Monitor xApp (foreground)..."
        echo "  Press Ctrl+C to stop all components."
        echo "═══════════════════════════════════════════════════════════════════════════"
        echo
        cd "$RIC_DIR"
        ./additional_scripts/run_xapp_gtp_mac_rlc_pdcp_moni.sh
        cd "$SCRIPT_DIR"
        ;;
    rc_moni)
        echo "═══════════════════════════════════════════════════════════════════════════"
        echo "  Starting RC Monitor xApp (foreground)..."
        echo "  Press Ctrl+C to stop all components."
        echo "═══════════════════════════════════════════════════════════════════════════"
        echo
        cd "$RIC_DIR"
        ./additional_scripts/run_xapp_rc_moni.sh
        cd "$SCRIPT_DIR"
        ;;
    kpm_rc)
        echo "═══════════════════════════════════════════════════════════════════════════"
        echo "  Starting KPM+RC Control xApp (foreground)..."
        echo "  Press Ctrl+C to stop all components."
        echo "═══════════════════════════════════════════════════════════════════════════"
        echo
        cd "$RIC_DIR"
        ./additional_scripts/run_xapp_kpm_rc.sh
        cd "$SCRIPT_DIR"
        ;;
    none)
        echo "═══════════════════════════════════════════════════════════════════════════"
        echo "  Testbed running (no xApp). Press Ctrl+C to stop all components."
        echo "═══════════════════════════════════════════════════════════════════════════"
        while true; do sleep 60; done
        ;;
    *)
        echo "Unknown xApp: $XAPP_NAME"
        echo "Valid: kpm_moni, kpm_moni_csv, gtp_mac_rlc_pdcp_moni, rc_moni, kpm_rc, none"
        exit 1
        ;;
esac
