#!/bin/bash
# Title: Recon Reporter
# Author: Codex
# Description: Generate structured recon reports (CSV + JSON) for selected APs/clients
# Version: 1.0
# Category: recon/general

# ============================================
# CONFIGURATION
# ============================================
OUTPUT_DIR="/root/loot/recon_reports"
PER_TARGET_DIR=true
ENABLE_JSON=true
ENABLE_CSV=true
INCLUDE_ENV_DUMP=true
ENABLE_DIFF=true
ALERT_ON_CHANGES=true
CLEANUP_DAYS=0

# ============================================
# HELPERS
# ============================================

json_escape() {
    # Escape JSON control characters without external deps
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/\\t/g' -e 's/\r/\\r/g' -e ':a;N;$!ba;s/\n/\\n/g'
}

csv_escape() {
    local val="$1"
    local esc
    esc=$(printf '%s' "$val" | sed 's/"/""/g')
    if printf '%s' "$val" | grep -q '[,\n"]'; then
        printf '"%s"' "$esc"
    else
        printf '%s' "$esc"
    fi
}

sanitize_id() {
    printf '%s' "$1" | tr ':' '-' | tr -cd '[:alnum:]_\-.'
}

now_ts() {
    date '+%Y%m%d-%H%M%S' 2>/dev/null || busybox date '+%Y%m%d-%H%M%S'
}

has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# ============================================
# MAIN EXECUTION
# ============================================

LOG green "=== Recon Reporter ==="

# Selected AP variables (best-effort; varies by firmware)
AP_SSID="${_RECON_SELECTED_AP_SSID}"
AP_BSSID="${_RECON_SELECTED_AP_BSSID:-$_RECON_SELECTED_AP_MAC_ADDRESS}"
AP_CHANNEL="${_RECON_SELECTED_AP_CHANNEL}"
AP_ENCRYPTION="${_RECON_SELECTED_AP_ENCRYPTION_TYPE:-$_RECON_SELECTED_AP_ENCRYPTION}"
AP_RSSI="${_RECON_SELECTED_AP_RSSI}"
AP_FREQUENCY="${_RECON_SELECTED_AP_FREQ:-$_RECON_SELECTED_AP_FREQUENCY}"
AP_PACKETS="${_RECON_SELECTED_AP_PACKETS}"
AP_CLIENTS="${_RECON_SELECTED_AP_CLIENT_COUNT:-$_RECON_SELECTED_AP_CLIENTS}"
AP_OUI="${_RECON_SELECTED_AP_OUI}"
AP_HIDDEN="${_RECON_SELECTED_AP_HIDDEN}"
AP_BEACONED_SSIDS="${_RECON_SELECTED_AP_BEACONED_SSIDS}"
AP_PROBED_SSIDS="${_RECON_SELECTED_AP_PROBED_SSIDS}"
AP_RESPONDED_SSIDS="${_RECON_SELECTED_AP_RESPONDED_SSIDS}"
AP_BEACONED_SSID="${_RECON_SELECTED_AP_BEACONED_SSID}"
AP_PROBED_SSID="${_RECON_SELECTED_AP_PROBED_SSID}"
AP_RESPONDED_SSID="${_RECON_SELECTED_AP_RESPONDED_SSID}"
AP_FIRST_SEEN="${_RECON_SELECTED_AP_TIMESTAMP}"

# Selected client variables (best-effort; varies by firmware)
CLIENT_MAC="${_RECON_SELECTED_CLIENT_MAC_ADDRESS:-$_RECON_SELECTED_CLIENT_MAC}"
CLIENT_RSSI="${_RECON_SELECTED_CLIENT_RSSI}"
CLIENT_FREQUENCY="${_RECON_SELECTED_CLIENT_FREQ:-$_RECON_SELECTED_CLIENT_FREQUENCY}"
CLIENT_PACKETS="${_RECON_SELECTED_CLIENT_PACKETS}"
CLIENT_OUI="${_RECON_SELECTED_CLIENT_OUI}"
CLIENT_ASSOC_BSSID="${_RECON_SELECTED_CLIENT_BSSID}"
CLIENT_BEACONED_SSIDS="${_RECON_SELECTED_CLIENT_BEACONED_SSIDS}"
CLIENT_PROBED_SSIDS="${_RECON_SELECTED_CLIENT_PROBED_SSIDS}"
CLIENT_RESPONDED_SSIDS="${_RECON_SELECTED_CLIENT_RESPONDED_SSIDS}"
CLIENT_BEACONED_SSID="${_RECON_SELECTED_CLIENT_BEACONED_SSID}"
CLIENT_PROBED_SSID="${_RECON_SELECTED_CLIENT_PROBED_SSID}"
CLIENT_RESPONDED_SSID="${_RECON_SELECTED_CLIENT_RESPONDED_SSID}"
CLIENT_FIRST_SEEN="${_RECON_SELECTED_CLIENT_TIMESTAMP}"

HAS_AP=false
HAS_CLIENT=false

if [ -n "$AP_BSSID" ] || [ -n "$AP_SSID" ]; then
    HAS_AP=true
fi

if [ -n "$CLIENT_MAC" ]; then
    HAS_CLIENT=true
fi

if [ "$HAS_AP" = false ] && [ "$HAS_CLIENT" = false ]; then
    ERROR_DIALOG "No recon target context found. Run from Recon on a selected AP or client."
    exit 1
fi

TS=$(now_ts)
BASE_ID="unknown"

if [ "$HAS_CLIENT" = true ]; then
    BASE_ID=$(sanitize_id "$CLIENT_MAC")
elif [ -n "$AP_BSSID" ]; then
    BASE_ID=$(sanitize_id "$AP_BSSID")
fi

mkdir -p "$OUTPUT_DIR" || {
    ERROR_DIALOG "Failed to create output dir: $OUTPUT_DIR"
    exit 1
}

TARGET_DIR="$OUTPUT_DIR"
if [ "$PER_TARGET_DIR" = true ]; then
    TARGET_DIR="$OUTPUT_DIR/$BASE_ID"
    mkdir -p "$TARGET_DIR" || {
        ERROR_DIALOG "Failed to create target dir: $TARGET_DIR"
        exit 1
    }
fi

JSON_FILE="$TARGET_DIR/${TS}_${BASE_ID}.json"
ENV_FILE="$TARGET_DIR/${TS}_${BASE_ID}.env"
LAST_FILE="$TARGET_DIR/last_fields.env"
CHANGE_FILE="$TARGET_DIR/${TS}_${BASE_ID}.changes.txt"

# --------------------------------------------
# JSON OUTPUT
# --------------------------------------------
if [ "$ENABLE_JSON" = true ]; then
    {
        echo "{"
        echo "  \"timestamp\": \"$(json_escape "$TS")\","
        echo "  \"payload\": \"recon_reporter\","

        if [ "$HAS_AP" = true ]; then
            echo "  \"ap\": {"
            echo "    \"ssid\": \"$(json_escape "$AP_SSID")\","
            echo "    \"bssid\": \"$(json_escape "$AP_BSSID")\","
            echo "    \"channel\": \"$(json_escape "$AP_CHANNEL")\","
            echo "    \"encryption\": \"$(json_escape "$AP_ENCRYPTION")\","
            echo "    \"rssi\": \"$(json_escape "$AP_RSSI")\","
            echo "    \"frequency\": \"$(json_escape "$AP_FREQUENCY")\","
            echo "    \"packets\": \"$(json_escape "$AP_PACKETS")\","
            echo "    \"clients\": \"$(json_escape "$AP_CLIENTS")\","
            echo "    \"oui\": \"$(json_escape "$AP_OUI")\","
            echo "    \"hidden\": \"$(json_escape "$AP_HIDDEN")\","
            echo "    \"beaconed_ssids\": \"$(json_escape "$AP_BEACONED_SSIDS")\","
            echo "    \"probed_ssids\": \"$(json_escape "$AP_PROBED_SSIDS")\","
            echo "    \"responded_ssids\": \"$(json_escape "$AP_RESPONDED_SSIDS")\","
            echo "    \"beaconed_ssid\": \"$(json_escape "$AP_BEACONED_SSID")\","
            echo "    \"probed_ssid\": \"$(json_escape "$AP_PROBED_SSID")\","
            echo "    \"responded_ssid\": \"$(json_escape "$AP_RESPONDED_SSID")\","
            echo "    \"first_seen\": \"$(json_escape "$AP_FIRST_SEEN")\""
            echo "  },"
        else
            echo "  \"ap\": null,"
        fi

        if [ "$HAS_CLIENT" = true ]; then
            echo "  \"client\": {"
            echo "    \"mac\": \"$(json_escape "$CLIENT_MAC")\","
            echo "    \"rssi\": \"$(json_escape "$CLIENT_RSSI")\","
            echo "    \"frequency\": \"$(json_escape "$CLIENT_FREQUENCY")\","
            echo "    \"packets\": \"$(json_escape "$CLIENT_PACKETS")\","
            echo "    \"oui\": \"$(json_escape "$CLIENT_OUI")\","
            echo "    \"associated_bssid\": \"$(json_escape "$CLIENT_ASSOC_BSSID")\","
            echo "    \"beaconed_ssids\": \"$(json_escape "$CLIENT_BEACONED_SSIDS")\","
            echo "    \"probed_ssids\": \"$(json_escape "$CLIENT_PROBED_SSIDS")\","
            echo "    \"responded_ssids\": \"$(json_escape "$CLIENT_RESPONDED_SSIDS")\","
            echo "    \"beaconed_ssid\": \"$(json_escape "$CLIENT_BEACONED_SSID")\","
            echo "    \"probed_ssid\": \"$(json_escape "$CLIENT_PROBED_SSID")\","
            echo "    \"responded_ssid\": \"$(json_escape "$CLIENT_RESPONDED_SSID")\","
            echo "    \"first_seen\": \"$(json_escape "$CLIENT_FIRST_SEEN")\""
            echo "  }"
        else
            echo "  \"client\": null"
        fi

        echo "}"
    } > "$JSON_FILE"
    if has_cmd ln; then
        ln -sf "$JSON_FILE" "$TARGET_DIR/last.json" 2>/dev/null
    fi
fi

# --------------------------------------------
# CSV OUTPUT
# --------------------------------------------
if [ "$ENABLE_CSV" = true ]; then
    AP_CSV="$OUTPUT_DIR/ap_summary.csv"
    CLIENT_CSV="$OUTPUT_DIR/client_summary.csv"

    if [ ! -f "$AP_CSV" ]; then
        echo "timestamp,ssid,bssid,channel,encryption,rssi,frequency,packets,clients,oui,hidden,beaconed_ssids,probed_ssids,responded_ssids,beaconed_ssid,probed_ssid,responded_ssid,first_seen" > "$AP_CSV"
    fi

    if [ ! -f "$CLIENT_CSV" ]; then
        echo "timestamp,client_mac,rssi,frequency,packets,oui,associated_bssid,beaconed_ssids,probed_ssids,responded_ssids,beaconed_ssid,probed_ssid,responded_ssid,first_seen" > "$CLIENT_CSV"
    fi

    if [ "$HAS_AP" = true ]; then
        echo "$(csv_escape "$TS"),$(csv_escape "$AP_SSID"),$(csv_escape "$AP_BSSID"),$(csv_escape "$AP_CHANNEL"),$(csv_escape "$AP_ENCRYPTION"),$(csv_escape "$AP_RSSI"),$(csv_escape "$AP_FREQUENCY"),$(csv_escape "$AP_PACKETS"),$(csv_escape "$AP_CLIENTS"),$(csv_escape "$AP_OUI"),$(csv_escape "$AP_HIDDEN"),$(csv_escape "$AP_BEACONED_SSIDS"),$(csv_escape "$AP_PROBED_SSIDS"),$(csv_escape "$AP_RESPONDED_SSIDS"),$(csv_escape "$AP_BEACONED_SSID"),$(csv_escape "$AP_PROBED_SSID"),$(csv_escape "$AP_RESPONDED_SSID"),$(csv_escape "$AP_FIRST_SEEN")" >> "$AP_CSV"
    fi

    if [ "$HAS_CLIENT" = true ]; then
        echo "$(csv_escape "$TS"),$(csv_escape "$CLIENT_MAC"),$(csv_escape "$CLIENT_RSSI"),$(csv_escape "$CLIENT_FREQUENCY"),$(csv_escape "$CLIENT_PACKETS"),$(csv_escape "$CLIENT_OUI"),$(csv_escape "$CLIENT_ASSOC_BSSID"),$(csv_escape "$CLIENT_BEACONED_SSIDS"),$(csv_escape "$CLIENT_PROBED_SSIDS"),$(csv_escape "$CLIENT_RESPONDED_SSIDS"),$(csv_escape "$CLIENT_BEACONED_SSID"),$(csv_escape "$CLIENT_PROBED_SSID"),$(csv_escape "$CLIENT_RESPONDED_SSID"),$(csv_escape "$CLIENT_FIRST_SEEN")" >> "$CLIENT_CSV"
    fi
fi

# --------------------------------------------
# ENV DUMP (DEBUG)
# --------------------------------------------
if [ "$INCLUDE_ENV_DUMP" = true ]; then
    env | grep '^_RECON_' > "$ENV_FILE"
fi

# --------------------------------------------
# DIFF (PREVIOUS RUN)
# --------------------------------------------
CHANGE_COUNT=0
CHANGE_SUMMARY=""

if [ "$ENABLE_DIFF" = true ]; then
    TMP_CUR="$TARGET_DIR/.current_fields.tmp"
    {
        echo "ap_ssid=$AP_SSID"
        echo "ap_bssid=$AP_BSSID"
        echo "ap_channel=$AP_CHANNEL"
        echo "ap_encryption=$AP_ENCRYPTION"
        echo "ap_rssi=$AP_RSSI"
        echo "ap_frequency=$AP_FREQUENCY"
        echo "ap_packets=$AP_PACKETS"
        echo "ap_clients=$AP_CLIENTS"
        echo "ap_oui=$AP_OUI"
        echo "ap_hidden=$AP_HIDDEN"
        echo "ap_beaconed_ssids=$AP_BEACONED_SSIDS"
        echo "ap_probed_ssids=$AP_PROBED_SSIDS"
        echo "ap_responded_ssids=$AP_RESPONDED_SSIDS"
        echo "ap_beaconed_ssid=$AP_BEACONED_SSID"
        echo "ap_probed_ssid=$AP_PROBED_SSID"
        echo "ap_responded_ssid=$AP_RESPONDED_SSID"
        echo "ap_first_seen=$AP_FIRST_SEEN"
        echo "client_mac=$CLIENT_MAC"
        echo "client_rssi=$CLIENT_RSSI"
        echo "client_frequency=$CLIENT_FREQUENCY"
        echo "client_packets=$CLIENT_PACKETS"
        echo "client_oui=$CLIENT_OUI"
        echo "client_associated_bssid=$CLIENT_ASSOC_BSSID"
        echo "client_beaconed_ssids=$CLIENT_BEACONED_SSIDS"
        echo "client_probed_ssids=$CLIENT_PROBED_SSIDS"
        echo "client_responded_ssids=$CLIENT_RESPONDED_SSIDS"
        echo "client_beaconed_ssid=$CLIENT_BEACONED_SSID"
        echo "client_probed_ssid=$CLIENT_PROBED_SSID"
        echo "client_responded_ssid=$CLIENT_RESPONDED_SSID"
        echo "client_first_seen=$CLIENT_FIRST_SEEN"
    } > "$TMP_CUR"

    if [ -f "$LAST_FILE" ]; then
        while IFS='=' read -r key curval; do
            prevval=$(grep -m1 "^${key}=" "$LAST_FILE" | cut -d= -f2-)
            if [ "$curval" != "$prevval" ]; then
                CHANGE_COUNT=$((CHANGE_COUNT + 1))
                CHANGE_SUMMARY="${CHANGE_SUMMARY}${key}: '${prevval}' -> '${curval}'\n"
            fi
        done < "$TMP_CUR"
    fi

    mv "$TMP_CUR" "$LAST_FILE"

    if [ "$CHANGE_COUNT" -gt 0 ]; then
        printf '%b' "$CHANGE_SUMMARY" > "$CHANGE_FILE"
    fi
fi

# --------------------------------------------
# CLEANUP
# --------------------------------------------
if [ "$CLEANUP_DAYS" -gt 0 ] 2>/dev/null; then
    if has_cmd find; then
        find "$OUTPUT_DIR" -type f -mtime +"$CLEANUP_DAYS" \( -name "*.json" -o -name "*.env" -o -name "*.changes.txt" \) 2>/dev/null | xargs rm -f 2>/dev/null
    fi
fi

# --------------------------------------------
# UI SUMMARY
# --------------------------------------------
if [ "$HAS_AP" = true ]; then
    LOG blue "AP: ${AP_SSID:-<hidden>} (${AP_BSSID})"
    LOG "Ch ${AP_CHANNEL} | ${AP_ENCRYPTION} | RSSI ${AP_RSSI}"
fi

if [ "$HAS_CLIENT" = true ]; then
    LOG blue "Client: ${CLIENT_MAC}"
    LOG "RSSI ${CLIENT_RSSI} | Assoc ${CLIENT_ASSOC_BSSID}"
fi

LOG green "Report saved to: $OUTPUT_DIR"
if [ "$ENABLE_JSON" = true ]; then
    LOG "JSON: $(basename "$JSON_FILE")"
fi
if [ "$INCLUDE_ENV_DUMP" = true ]; then
    LOG "ENV: $(basename "$ENV_FILE")"
fi
if [ "$ENABLE_DIFF" = true ]; then
    if [ "$CHANGE_COUNT" -gt 0 ]; then
        LOG yellow "Changes detected: $CHANGE_COUNT"
        if [ "$ALERT_ON_CHANGES" = true ]; then
            ALERT "Recon changes detected: $CHANGE_COUNT\nSaved: $(basename "$CHANGE_FILE")"
        fi
    else
        LOG green "No changes detected"
    fi
fi

exit 0
