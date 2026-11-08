<div align="center">
  <img src="assets/banner.svg" alt="Dark Sec Labz — Pineapple Pager Payloads" width="100%">
</div>

<h1 align="center">Pineapple Pager Payloads</h1>

<p align="center">
  <b>Offensive wireless, network and OSINT payloads for the Hak5 WiFi Pineapple Pager.</b><br>
  Built for firmware <b>2.0.0-stable</b> · <code>mipsel</code> · authorization-gated · loot-first
</p>

<p align="center">
  <img src="https://img.shields.io/badge/firmware-2.0.0--stable-6b3fa0?style=for-the-badge" alt="Firmware 2.0.0-stable">
  <img src="https://img.shields.io/badge/platform-mipsel-7a5cff?style=for-the-badge" alt="mipsel">
  <img src="https://img.shields.io/badge/payloads-11-ff2fd6?style=for-the-badge" alt="11 payloads">
  <img src="https://img.shields.io/badge/license-MIT-d1acff?style=for-the-badge" alt="MIT">
  <img src="https://img.shields.io/badge/PRs-welcome-8b5cf6?style=for-the-badge" alt="PRs welcome">
</p>

<p align="center">
  <a href="#payload-index">Payload index</a> ·
  <a href="#featured-payloads">Featured payloads</a> ·
  <a href="#quick-start">Quick start</a> ·
  <a href="#dependencies">Dependencies</a> ·
  <a href="#loot-paths">Loot paths</a> ·
  <a href="#legal">Legal</a> ·
  <a href="#contributing">Contributing</a>
</p>

---

## Why this repo

A curated set of Pager payloads that go beyond the stock library: discovery
honeypots, IoT exploitation, a full web pentest console, phone-number OSINT,
enterprise Wi-Fi credential capture, username recon, and handshake tooling.

Every payload is built around the same rules:

- **Authorized testing only** — explicit scope gate before any active step
- **Reversible** — services, interfaces and files are restored on exit
- **Loot-first** — results land in a predictable `/root/loot/<payload>/` path
- **Self-contained** — pure Python/shell wherever possible, no surprise binaries

---

## Payload index

| Payload | Layer | Highlights | Firmware | Docs |
| --- | --- | --- | --- | --- |
| 📺 **MIRRORCAST** | Interception | mDNS/SSDP cast + print honeypot, print capture, castjack | 2.0.0+ | [Docs](mirrorcast/README.md) |
| 🔌 **IoTJACK** | Interception | Kasa / MQTT / UPnP IGD / TR-064 / RTSP / PJL modules | 2.0.0+ | [Docs](iotjack/README.md) |
| 🧙 **PWRLVL9000** | Interception | 9-tab web console, XP leveling, handshake vault | 2.0.0+ | [Docs](pwrlvl9000/README.md) |
| 📞 **PHONEPHREAK** | Recon | E.164, line type, link pack, QR handoff, bulk mode | 2.0.0+ | [Docs](phonephreak/README.md) |
| 🎥 **FlockAudit** | Recon | Flock Safety LPR camera detection + KML export | Classic Pineapple | [Docs](FlockAudit/README.md) |
| 📊 **Recon Reporter** | Recon | CSV + JSON recon exports from the Recon UI | Pager | [Docs](library/recon/general/recon_reporter/README.md) |
| 🎭 **VENOM** | Exfiltration | Rogue WPA-Enterprise AP, EAP identity + credential capture | Pager | [Docs](venom/README.md) |
| 🕵️ **Sherlock** | OSINT | Username hunt across 80+ platforms | Pager | [Docs](Sherlock/README.md) |
| ⚡ **Auto Handshake Cracker** | Alerts | Auto-crack captured WPA handshakes | Pager | [Docs](autocrack/alerts/handshake_captured/auto_crack/README.md) |
| 🔓 **Interactive Handshake Cracker** | Exfiltration | Manual handshake cracking with live progress | Pager | [Docs](autocrack/user/exfiltration/handshake_cracker/README.md) |
| 📚 **Wordlist Manager** | General | Download and organize wordlists | Pager | [Docs](autocrack/user/general/wordlist_manager/README.md) |

> The four featured payloads are actively maintained for **2.0.0-stable**. The
> remaining payloads are included as-is; test them against your firmware before
> relying on them in an engagement.

---

## Featured payloads

### 📺 MIRRORCAST — Cast & Print Honeypot

Impersonates the AirPlay, DIAL, Chromecast and IPP printer services that clients
expect to find on a network, logs every device that comes looking, captures
print jobs, and can push media to real cast devices.

- Seven mDNS/SSDP service identities, including DLNA and IPP printers
- Raw print-job capture plus extracted document
- Castjack mode for Chromecast / AirPlay / DIAL / DLNA, with dry-run preview
- A-button stop and JSONL loot stream

```text
Install: /root/payloads/user/interception/mirrorcast
Loot:    /root/loot/mirrorcast/
```

[Full documentation →](mirrorcast/README.md)

### 🔌 IoTJACK — IoT Exploitation Toolkit

Scans the LAN, fingerprints IoT devices, then speaks each target's own protocol
in pure Python. No external exploit binaries.

| Module | Protocol | Read | Write (confirmed on screen) |
| --- | --- | --- | --- |
| Kasa | TP-Link XOR/JSON, TCP 9999 | sysinfo, Wi-Fi creds, cloud account, power meter | Relay toggle |
| MQTT | MQTT 3.1.1 | Anonymous subscribe / capture | Publish |
| UPnP IGD | SOAP | Device + service map | Add/remove NAT mapping |
| TR-064 | SOAP over HTTP | Router keys / config | — |
| RTSP | RTSP | Camera identity, default-cred test | — |
| PJL | Printer Job Language | Printer readout | Display message |

```text
Install: /root/payloads/user/interception/iotjack
Loot:    /root/loot/iotjack/
```

[Full documentation →](iotjack/README.md)

### 🧙 PWRLVL9000 — Pentest Web Console

A browser-based pentesting dashboard on port **9000**, served from the Pager.
Nine tabs cover Wi-Fi, probes, rogue APs, WPS, web and port scanning, packet
capture, a handshake vault, and a root shell — with XP leveling and live SSE
events.

- Firmware-managed monitor interfaces (`wlan0mon`, `wlan1mon`, `wlan2mon`)
- `airodump-ng`, `hostapd`, `reaver`, `mdk4`, `tcpdump` automation
- Handshake cracking and `.22000` conversion in the Loot tab
- On-device LOG display by default; `pagerctl` graphical display is opt-in

```text
Install: /root/payloads/user/interception/pwrlvl9000
Open:    http://172.16.42.1:9000
Loot:    /root/loot/pwrlvl9000/
```

[Full documentation →](pwrlvl9000/README.md)

### 📞 PHONEPHREAK — Phone Number OSINT

Turns a phone number into a PhoneInfoga-style report. Fully offline by default,
with an optional exact-match web footprint check.

- E.164 validation and normalization for ~150 calling codes
- Country, timezone, and line-type detection (mobile / landline / VoIP /
  toll-free / premium)
- Format variants and an investigation link pack (WhatsApp, Telegram, search
  dorks, Truecaller, sync.me, carrier lookups)
- QR handoff of the `wa.me` link, plus bulk mode with `.txt` + `.json` reports

```text
Install: /root/payloads/user/reconnaissance/phonephreak
Loot:    /root/loot/phonephreak/
```

[Full documentation →](phonephreak/README.md)

---

## Quick start

### Install from your computer

```sh
git clone https://github.com/sinXne0/pineapple-pager-payloads.git
cd pineapple-pager-payloads

scp -r mirrorcast iotjack pwrlvl9000 \
  root@172.16.42.1:/root/payloads/user/interception/
scp -r phonephreak \
  root@172.16.42.1:/root/payloads/user/reconnaissance/
```

Then make the launchers executable:

```sh
ssh root@172.16.42.1 '
  chmod +x /root/payloads/user/interception/*/payload.sh
  chmod +x /root/payloads/user/reconnaissance/phonephreak/payload.sh
'
```

### Install directly on the Pager

```sh
ssh root@172.16.42.1

mkdir -p /root/payloads/user/interception /root/payloads/user/reconnaissance
cd /root/payloads/user
git clone --depth 1 https://github.com/sinXne0/pineapple-pager-payloads.git

cp -r pineapple-pager-payloads/mirrorcast \
      pineapple-pager-payloads/iotjack \
      pineapple-pager-payloads/pwrlvl9000 \
      /root/payloads/user/interception/
cp -r pineapple-pager-payloads/phonephreak \
      /root/payloads/user/reconnaissance/

chmod +x /root/payloads/user/interception/*/payload.sh \
         /root/payloads/user/reconnaissance/phonephreak/payload.sh
```

Launch any payload from **Payloads → User Payloads** on the Pager.

---

## Dependencies

| Payload | Required | Optional |
| --- | --- | --- |
| MIRRORCAST | `python3-light` | `python3-openssl` for Chromecast castjack |
| IoTJACK | `python3-light` | — |
| PWRLVL9000 | `python3-light`, `aircrack-ng` | `hostapd`, `dnsmasq`, `reaver`, `mdk4`, `tcpdump`, `iw` |
| PHONEPHREAK | `python3-light` | `python3-openssl` for the online footprint check |
| VENOM | `wpad-openssl`, `openssl-util`, `iw` | `tcpdump` |
| Handshake tooling | `aircrack-ng` | — |
| Sherlock | `curl` | — |

Install the common base:

```sh
opkg update
opkg install python3-light
```

Install the full PWRLVL9000 toolset:

```sh
opkg install aircrack-ng hostapd dnsmasq reaver mdk4 tcpdump iw
```

Each payload also offers to install its own missing dependencies on first run.

---

## Loot paths

| Payload | Output |
| --- | --- |
| MIRRORCAST | `/root/loot/mirrorcast/` (JSONL events, print jobs) |
| IoTJACK | `/root/loot/iotjack/` (JSONL events, module output) |
| PWRLVL9000 | `/root/loot/pwrlvl9000/` and `/tmp/pwrlvl9000.log` |
| PHONEPHREAK | `/root/loot/phonephreak/` (`.txt` + `.json`) |
| VENOM | `/root/loot/venom/` |
| Sherlock | `/root/loot/sherlock/` |
| FlockAudit | `/root/loot/FlockAudit/` (report + KML) |
| Recon Reporter | `/root/loot/recon_reports/` (CSV + JSON) |
| Handshake Cracker | `/root/cracked_passwords.txt` |

---

## Repository layout

```text
.
├── assets/                      Banner artwork
├── mirrorcast/                  Cast & print honeypot
├── iotjack/                     IoT exploitation framework
├── pwrlvl9000/                  Web pentest console
├── phonephreak/                 Phone-number OSINT
├── FlockAudit/                  Flock Safety LPR camera audit
├── venom/                       WPA-Enterprise credential harvester
├── Sherlock/                    Username OSINT
├── autocrack/                   Handshake cracking + wordlists
├── library/recon/general/       Recon Reporter payload
├── CONTRIBUTING.md
└── LICENSE
```

---

## Compatibility and safety

- Targets **WiFi Pineapple Pager** hardware with firmware **2.0.0-stable**.
- Uses the firmware-managed monitor interfaces on 2.0.0; older firmware falls
  back to the classic `iw` monitor toggle where supported.
- No destructive persistence: cleanup traps stop services, remove temporary
  interfaces, and restore display state.
- The only bundled binary is PWRLVL9000's `libpagerctl.so` (mipsel); everything
  else is shell or pure Python.

---

## Legal

These payloads are for **authorized security testing, research, and education
only**. Run them only against networks, devices, and accounts you own or have
explicit written permission to test. You are responsible for your engagement
scope, local law, and the terms of any third-party service you query.

The authors accept no liability for misuse or damage.

---

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

- One payload per pull request
- Tested on real Pager hardware
- Unix LF line endings, `mipsel` target
- Include a payload header with `Title`, `Author`, `Description`, `Version`,
  `Category`, and `Firmware`
- Keep write actions explicit and reversible

---

## Credits

- [Hak5](https://hak5.org) for the WiFi Pineapple Pager and payload framework
- `bad-antics` for FlockAudit
- `sinX` for the classic handshake and wordlist payloads
- Everyone who has reported bugs and tested payloads on hardware

## License

[MIT](LICENSE) © 2026 sinX
