# FlockAudit

**WiFi Pineapple payload for authorized auditing of Flock Safety LPR camera deployments.**

Detects Flock Safety license plate reader (LPR) cameras by passively scanning the airspace for their management WiFi access points and probe requests — no network connection or shared subnet required. GPS-tags every finding and exports results to both a plain-text report and a KML file for mapping.

> **For authorized security assessments only.** Only use this tool against infrastructure you own or have explicit written permission to test.

---

## What It Does

### Phase 1 — Beacon Scan (OUI + SSID)
Puts the Pineapple's radio into monitor mode and runs `airodump-ng` for a configurable duration. Every AP beacon is checked against:
- A curated list of **hardware OUIs** used by Flock camera components (Raspberry Pi compute modules, NVIDIA Jetson, Hikvision, Dahua, Axis, Hanwha/Wisenet, Bosch/Azena, Vivotek, Mobotix, Genetec, March Networks)
- An **SSID pattern list** (`Flock_`, `FlockSafety`, `FLOCK-`, `LPR-`, `PlateReader`, `CommunityAlert`, `SafetyCam`, `ALPRCam`)

### Phase 2 — Probe Request Sniff
Captures probe requests from client devices. Any client probing for a Flock-pattern SSID is flagged — these are devices that have previously connected to a Flock camera AP, indicating a camera was (or is) nearby.

### Phase 3 — GPS Tagging + Export
Every detection is tagged with GPS coordinates (requires GPS module), written to a timestamped text report, and added to a KML file viewable in Google Earth or Maps.

### Phase 4 — Deep Probe (optional)
When a camera AP is found, the payload can optionally:
1. Connect to the camera's own WiFi network
2. Obtain an IP via DHCP
3. Run a port scan against the camera's gateway IP (`nmap -sV`)
4. Pull HTTP banners and page titles
5. Query vendor-specific APIs: **Hikvision ISAPI**, **Dahua CGI**, **Axis VAPIX**
6. Test RTSP stream availability (no-auth check)
7. Test a list of **default credentials** against the web interface

### Watch Mode
Loops the scan continuously — useful when driving a route to map camera density across an area.

---

## Requirements

| Requirement | Notes |
|-------------|-------|
| WiFi Pineapple (Mark VII / Nano / Tetra) | Running current firmware |
| `airodump-ng` / `airmon-ng` | Part of `aircrack-ng` package on Pineapple |
| `nmap` | Required for deep probe port scan |
| `curl` | Required for HTTP / vendor API probing |
| `nc` (netcat) | Required for RTSP probe |
| `udhcpc` | Required for deep probe DHCP |
| GPS module | Optional — enables coordinate tagging and KML output |

---

## Installation

1. Copy `payload.sh` to your Pineapple via the **Payloads** module or SSH:

```bash
scp payload.sh root@172.16.42.1:/root/payloads/FlockAudit/payload.sh
```

2. In the Pineapple web UI, navigate to **Payloads → FlockAudit** and arm it.

3. Trigger execution by plugging the Pineapple into a power source with the payload armed, or run directly via SSH:

```bash
bash /root/payloads/FlockAudit/payload.sh
```

---

## Configuration

All options are selected interactively at runtime via the Pineapple UI prompts:

| Option | Description | Default |
|--------|-------------|---------|
| **Scan duration** | Seconds per airodump-ng pass | `30` |
| **Watch mode** | Loop scan continuously (for driving routes) | Off |
| **Deep probe** | Auto-connect to found camera APs and probe them | Off |

---

## Output

All output lands in `/root/loot/FlockAudit/` on the Pineapple:

```
/root/loot/FlockAudit/
├── flock_YYYYMMDD_HHMMSS.txt    ← plain-text report
└── flock_YYYYMMDD_HHMMSS.kml    ← Google Earth / Maps KML
```

### Report format

```
========================================
  FLOCK SAFETY CAMERA AUDIT
  Session: 20250101_120000
  Start GPS: 26.712, -80.053
========================================

[BEACON 1]
  BSSID:   B8:27:EB:AA:BB:CC
  SSID:    Flock_CAM_0042
  Channel: 6
  Signal:  -61 dBm
  Vendor:  Raspberry Pi (Flock early)
  GPS:     26.7125, -80.0531

[DEEP PROBE: Flock_CAM_0042 / 192.168.4.1]
  HTTP http:80
    Title: IPCamera
    Server: Hikvision-Webs
  Hikvision ISAPI:
    deviceName: Flock LPR-HD
    model: DS-2CD2085G1
    serialNumber: DS-2CD...
  *** DEFAULT CREDS WORK: admin:12345 (port 80) ***
```

### KML output

Open the `.kml` file in Google Earth, Google Maps (import), or any GIS tool to see a pin-drop map of every detected camera with signal strength and vendor info.

---

## OUI Coverage

The payload checks against OUIs for hardware vendors known to be used in Flock Safety deployments:

- Raspberry Pi Foundation (early Flock units)
- NVIDIA Jetson (current Flock compute platform)
- Hikvision, Dahua, Axis, Hanwha/Wisenet (camera modules)
- Bosch/Azena, Vivotek, Mobotix, Genetec, March Networks

---

## SSID Patterns Detected

```
Flock_         FlockSafety    FLOCK-
flock-cam      LPR-           PlateReader
CommunityAlert SafetyCam      ALPRCam
```

---

## Default Credentials Tested (Deep Probe)

The deep probe phase tests the following credentials against the camera's web interface:

```
admin:admin      admin:12345      admin:password
admin:123456     admin:(blank)    root:root
root:12345       admin:Admin12345
888888:888888    666666:666666
```

---

## Legal

This tool is intended **exclusively** for:
- Security audits of infrastructure you own
- Authorized penetration testing engagements with written scope approval
- Law enforcement or government assessments with appropriate authorization

Scanning, connecting to, or probing devices without authorization may violate the Computer Fraud and Abuse Act (CFAA), state computer crime laws, and FCC regulations. The author assumes no liability for unauthorized use.
