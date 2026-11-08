# Sherlock - Username OSINT

Hunt a username across 80+ social networks, developer platforms, gaming
sites and community services directly from the WiFi Pineapple Pager.

> **Authorized research only.** Sherlock checks public profile URLs; use it
> only for accounts and investigations you are authorized to perform.

## What it does

- Accepts a username (with or without a leading `@`) and validates the
  character set before scanning.
- Checks each platform in the built-in site list with `curl`, using one of
  three matchers:
  - **status** - HTTP 200 means the profile exists
  - **msg** - a known "not found" marker in the page body means no profile
  - **url** - final redirected URL contains a known hit marker
- Streams progress and hits to the Pager screen as each site is checked.
- Saves the hit list and a summary to loot.

## Requirements

- WiFi Pineapple Pager with network access
- `curl` (present on the stock firmware)

## Usage

1. Run **Sherlock** from the Pager payload menu.
2. Enter the username to investigate.
3. Confirm the scan. Results appear live; a summary is shown at the end.

## Loot

```text
/root/loot/sherlock/<username>_<YYYYMMDD_HHMMSS>.txt
```

The report lists each matching platform and profile URL, then the final
`Found: N / Total` count.

## Notes and limits

- Social platforms change their markup and anti-bot behaviour regularly, so
  individual site checks can produce false negatives over time.
- Some sites rate-limit or block `curl`; those checks simply miss.
- The payload is read-only: it requests public profile URLs and does not log
  in, scrape private data or modify anything.

## Uninstall

```sh
rm -rf /root/payloads/user/Sherlock /root/loot/sherlock
```
