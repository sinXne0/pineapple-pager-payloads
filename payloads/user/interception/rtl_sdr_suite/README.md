# RTL-SDR Live Suite (Pager Payload)

Enables RTL-SDR / NESDR Smart dongles on the WiFi Pineapple Pager, installs drivers if needed, and starts live SDR streaming or spectrum scans.

## Features

- Auto-installs RTL-SDR packages via `opkg`
- Start `rtl_tcp` for live viewing from a PC
- Start `rtl_power` for spectrum logging
- Start `rtl_adsb` for ADS-B plane tracking (logs)
- Start `dump1090` for ADS-B web UI
- Stop/start/status control

## Requirements

- Internet access for `opkg` install (first run only)
- RTL-SDR / NESDR Smart plugged into the Pager
- A PC with SDR++ / Gqrx / SDR# for live viewing

## Usage

1. Copy payload folder to the Pager:
   ```bash
   scp -r rtl_sdr_suite root@172.16.42.1:/root/payloads/user/interception/
   ```
2. Make executable:
   ```bash
   chmod +x /root/payloads/user/interception/rtl_sdr_suite/payload.sh
   ```
3. Run from the Pager UI.

### Mode Options

- `tcp` = start live streaming server (`rtl_tcp`)
- `power` = start spectrum logging (`rtl_power`)
- `adsb` = start ADS-B receiver (`rtl_adsb`)
- `adsb-web` = start ADS-B web UI (`dump1090`)
- `both` = start both
- `stop` = stop all SDR processes
- `status` = show running status

## Live Viewing (PC)

- Connect your PC to the Pager network.
- Open SDR++ / Gqrx / SDR#.
- Choose **RTL-TCP** as source.
- Use Pager IP and port `1234`.

## Output Logs

`rtl_power` logs are stored in:

```
/root/loot/rtl_sdr/
```

## Configuration

Edit `payload.sh` to change:

- `GAIN` (0 for auto)
- `FREQ_START`, `FREQ_END`, `FREQ_STEP`
- `POWER_INTERVAL`, `POWER_DURATION`
- `RTL_TCP_PORT`, `SAMPLE_RATE`
- `ADSB_WEB_PORT`
