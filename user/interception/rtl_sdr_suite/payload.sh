#!/bin/bash
# Title: RTL-SDR Live Suite
# Author: sinXne0
# Description: Install RTL-SDR drivers and start live SDR streams or spectrum scans
# Version: 1.0
# Category: user/interception

# ============================================
# CONFIGURATION
# ============================================
RTL_TCP_PORT=1234
DEVICE_INDEX=0
GAIN=20            # 0 for auto
PPM=0
SAMPLE_RATE=2048000

FREQ_START="88M"
FREQ_END="108M"
FREQ_STEP="200k"
POWER_INTERVAL=10
POWER_DURATION="1h"

LOOT_DIR="/root/loot/rtl_sdr"
TCP_PID_FILE="/tmp/rtl_tcp.pid"
POWER_PID_FILE="/tmp/rtl_power.pid"
TCP_LOG="/tmp/rtl_tcp.log"

ADSB_GAIN=40
ADSB_PPM=0
ADSB_PID_FILE="/tmp/rtl_adsb.pid"
ADSB_LOG_DIR="/root/loot/rtl_sdr"
ADSB_LOG=""

# ============================================
# HELPERS
# ============================================
get_ip() {
  ip -4 -o addr show | awk '!/127.0.0.1/ {print $4}' | head -n1 | cut -d/ -f1
}

is_running_pid() {
  local pid_file="$1"
  if [ -f "$pid_file" ]; then
    local pid
    pid=$(cat "$pid_file" 2>/dev/null)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

check_connectivity() {
  if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

check_deps() {
  if command -v rtl_tcp >/dev/null 2>&1 && command -v rtl_power >/dev/null 2>&1; then
    LOG green "RTL-SDR tools already installed"
    return 0
  fi

  LOG yellow "Installing RTL-SDR packages..."
  SPINNER "Installing rtl-sdr..."

  if ! check_connectivity; then
    ERROR_DIALOG "No internet connectivity\nConnect Pager to internet and retry"
    return 1
  fi

  opkg update >/dev/null 2>&1

  for pkg in rtl-sdr librtlsdr rtl-sdr-apps; do
    if ! opkg list-installed 2>/dev/null | grep -q "^${pkg} "; then
      opkg install "$pkg" >/dev/null 2>&1
    fi
  done

  if command -v rtl_tcp >/dev/null 2>&1 && command -v rtl_power >/dev/null 2>&1; then
    LOG green "RTL-SDR tools installed"
    return 0
  fi

  ERROR_DIALOG "RTL-SDR install failed\nCheck opkg and try again"
  return 1
}

start_rtl_tcp() {
  if is_running_pid "$TCP_PID_FILE"; then
    LOG yellow "rtl_tcp already running"
    return 0
  fi

  local ip
  ip=$(get_ip)

  LOG green "Starting rtl_tcp on ${ip}:${RTL_TCP_PORT}"
  SPINNER "Starting rtl_tcp..."

  mkdir -p "$LOOT_DIR" 2>/dev/null

  if [ "$GAIN" -gt 0 ] 2>/dev/null; then
    rtl_tcp -a 0.0.0.0 -p "$RTL_TCP_PORT" -d "$DEVICE_INDEX" -g "$GAIN" -s "$SAMPLE_RATE" >"$TCP_LOG" 2>&1 &
  else
    rtl_tcp -a 0.0.0.0 -p "$RTL_TCP_PORT" -d "$DEVICE_INDEX" -s "$SAMPLE_RATE" >"$TCP_LOG" 2>&1 &
  fi

  echo $! > "$TCP_PID_FILE"
  LOG green "rtl_tcp started"
  ALERT "RTL-TCP live stream ready\nConnect from PC to ${ip}:${RTL_TCP_PORT}"
}

start_rtl_power() {
  if is_running_pid "$POWER_PID_FILE"; then
    LOG yellow "rtl_power already running"
    return 0
  fi

  mkdir -p "$LOOT_DIR" 2>/dev/null
  local out_file
  out_file="$LOOT_DIR/rtl_power_$(date +%Y%m%d_%H%M%S).csv"

  LOG green "Starting rtl_power scan"
  LOG "Range: $FREQ_START-$FREQ_END step $FREQ_STEP"
  SPINNER "Starting rtl_power..."

  if [ "$GAIN" -gt 0 ] 2>/dev/null; then
    rtl_power -f ${FREQ_START}:${FREQ_END}:${FREQ_STEP} -g "$GAIN" -p "$PPM" -i "$POWER_INTERVAL" -e "$POWER_DURATION" "$out_file" >/dev/null 2>&1 &
  else
    rtl_power -f ${FREQ_START}:${FREQ_END}:${FREQ_STEP} -p "$PPM" -i "$POWER_INTERVAL" -e "$POWER_DURATION" "$out_file" >/dev/null 2>&1 &
  fi

  echo $! > "$POWER_PID_FILE"
  LOG green "rtl_power running"
  ALERT "rtl_power logging to\n$out_file"
}


start_adsb() {
  if is_running_pid "$ADSB_PID_FILE"; then
    LOG yellow "rtl_adsb already running"
    return 0
  fi

  mkdir -p "$ADSB_LOG_DIR" 2>/dev/null
  ADSB_LOG="$ADSB_LOG_DIR/adsb_$(date +%Y%m%d_%H%M%S).txt"

  LOG green "Starting ADS-B receiver"
  SPINNER "Starting rtl_adsb..."

  if [ "$ADSB_GAIN" -gt 0 ] 2>/dev/null; then
    rtl_adsb -g "$ADSB_GAIN" -p "$ADSB_PPM" | tee "$ADSB_LOG" >/dev/null &
  else
    rtl_adsb -p "$ADSB_PPM" | tee "$ADSB_LOG" >/dev/null &
  fi

  echo $! > "$ADSB_PID_FILE"
  LOG green "rtl_adsb running"
  ALERT "ADS-B receiver started\nLogging: $ADSB_LOG"
}

stop_all() {
  if is_running_pid "$TCP_PID_FILE"; then
    kill "$(cat "$TCP_PID_FILE")" 2>/dev/null
    rm -f "$TCP_PID_FILE"
    LOG green "Stopped rtl_tcp"
  fi

  if is_running_pid "$POWER_PID_FILE"; then
    kill "$(cat "$POWER_PID_FILE")" 2>/dev/null
    rm -f "$POWER_PID_FILE"
    LOG green "Stopped rtl_power"
  fi

  if is_running_pid "$ADSB_PID_FILE"; then
    kill "$(cat "$ADSB_PID_FILE")" 2>/dev/null
    rm -f "$ADSB_PID_FILE"
    LOG green "Stopped rtl_adsb"
  fi

  ALERT "SDR processes stopped"
}

status() {
  local ip
  ip=$(get_ip)

  if is_running_pid "$TCP_PID_FILE"; then
    LOG green "rtl_tcp: RUNNING (${ip}:${RTL_TCP_PORT})"
  else
    LOG yellow "rtl_tcp: STOPPED"
  fi

  if is_running_pid "$POWER_PID_FILE"; then
    LOG green "rtl_power: RUNNING"
  else
    LOG yellow "rtl_power: STOPPED"
  fi

  if is_running_pid "$ADSB_PID_FILE"; then
    LOG green "rtl_adsb: RUNNING"
  else
    LOG yellow "rtl_adsb: STOPPED"
  fi
}

# ============================================
# MAIN
# ============================================
LOG green "=== RTL-SDR Live Suite ==="

resp=$(TEXT_PICKER "Mode (tcp/power/adsb/both/stop/status)" "tcp")
case $? in
  $DUCKYSCRIPT_CANCELLED|$DUCKYSCRIPT_REJECTED)
    exit 0
    ;;
esac

MODE=$(echo "$resp" | tr '[:upper:]' '[:lower:]' | tr -d ' ')

case "$MODE" in
  tcp)
    check_deps || exit 1
    start_rtl_tcp
    ;;
  power)
    check_deps || exit 1
    start_rtl_power
    ;;
  adsb)
    check_deps || exit 1
    start_adsb
    ;;
  both)
    check_deps || exit 1
    start_rtl_tcp
    start_rtl_power
    ;;
  stop)
    stop_all
    ;;
  status)
    status
    ;;
  *)
    ERROR_DIALOG "Unknown mode: $MODE\nUse tcp, power, both, stop, or status"
    exit 1
    ;;
esac
