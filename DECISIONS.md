# Decisions

Why the plan looks the way it does. Newest first.

## 2026-11-22 — Original audio, Spanish subtitles; add Bazarr

**Decision:** Radarr/Sonarr prefer the original-language release (Radarr profile language **Original**; Sonarr custom format `Audio original` scored 100), capped at 1080p. Bazarr downloads Spanish subtitles with English as fallback.

**Why:** Dad prefers original audio with Spanish or English subtitles. Releases often lack Spanish subs, so relying on what's embedded isn't enough. 1080p cap because 4K files (20–60 GB) would fill 256 GB quickly.

## 2026-11-22 — Runbook instead of backups for app state

**Decision:** No backups of `/var/lib/*`. RUNBOOK.md records every app setting so a rebuild can redo them by hand.

**Why:** App state already survives reboots, upgrades and NixOS rollbacks (rollbacks don't touch `/var/lib`). It's only lost if the disk dies or the box is reinstalled, which is rare, and redoing the setup from a checklist takes about an hour. Declaring app settings in Nix isn't worth it: qBittorrent's `serverConfig` overwrites UI changes and needs the password hash in a public repo; Jellyfin and the *arr apps keep most settings in databases.

**Trade-off:** After a disk failure, watch history, users and request history are gone.

## 2026-11-22 — First install findings

- **CPU is a Ryzen 5 3501U**, not the assumed 3500U. Same Vega iGPU, VAAPI works.
- **The iGPU reserves 3 GB of the 8 GB RAM** (BIOS UMA frame buffer), leaving 4.7 GB. Jellyfin's transcoding needs little dedicated VRAM, so the plan is to drop it to 512M–1G.
- **The M.2 drive is SATA**, not NVMe.
- **`services.jellyseerr` is now `services.seerr`** in NixOS 26.05 (Seerr and Overseerr merged into Seerr).
- **Modules for File Browser, qBittorrent, Radarr and Sonarr set their own `UMask`**, so ours uses `lib.mkForce "0002"` to keep files group-writable for the `media` group.
- **First switch is done from a local copy** (`path:` flake on the server) because the repo isn't on GitHub yet.

## 2026-11-22 — Radarr/Sonarr/Prowlarr/Seerr in phase 1

**Decision:** Full automation from day one. Dad requests in Seerr; Radarr/Sonarr find, download, rename and hardlink into the library, then remove the torrent after seeding.

**Why:** On my girlfriend's OpenMediaVault + compose setup, the biggest pain is the manual step after a download: remove the torrent, rename files, move them into the Jellyfin folders, from a terminal. Dad shouldn't do that. Native NixOS services sharing one `media` group and one `/srv/media` filesystem avoid the container path-mapping problems and make hardlinks work.

**Trade-offs:** About an hour of web UI setup on my side, four more services (~1–1.5 GB RAM total, fine on 8 GB), and FlareSolverr for Cloudflare-protected sites.

## 2026-11-22 — Dashboard: Spanish, status and storage; File Browser for manual fixes

**Decision:** The static page has four buttons (Ver, Pedir, Descargas, Archivos), a status dot per service, a storage bar, a short how-to, and admin links. File Browser covers manual moves, renames and uploads without a terminal.

**Why:** Dad's Spanish. Status and storage are what he'd check; anything deeper is done in each app. Status works by nginx proxying each service on the same address (502/504 = down); storage comes from a one-minute timer writing `df` output to JSON. Still no dashboard app to maintain.

## 2026-11-22 — Static dashboard page instead of Homepage

**Decision:** nginx serves one hand-written HTML page. Dropped the Homepage dashboard service.

**Why:** The server's IP isn't known in advance, and Homepage needs absolute links and an allowed-hosts list. The static page builds its links from whatever address the browser used, so it works on any IP with no config change. One less service to break.

## 2026-11-22 — qBittorrent password and save path set in the web UI

**Decision:** No `serverConfig` in the NixOS module.

**Why:** The module rewrites qBittorrent.conf from `serverConfig` on start, which would overwrite the password set in the UI, and putting the password hash in a public repo isn't great.

## 2026-11-22 — Flake repo with small modules; server pulls from git

**Decision:** Config is a flake pinned to `nixos-26.05`, split into one module per concern, public on GitHub. The server builds straight from `github:Betucciny/NixOsMediaCenter` (no local clone). I update `flake.lock` from my laptop; the server never updates its own inputs.

**Why:**
- The lock file pins the exact nixpkgs, so the server runs what I tested, not whatever was newest that week.
- Small modules keep each service readable and easy to switch off.
- Pulling from GitHub works through AnyDesk + SSH with no inbound access needed. Pushing builds from my laptop (`--target-host`) only works when I can reach the server directly.
- Building from the `github:` URL means no clone on the server to keep in sync or get dirty.
- Public repo: the server needs no credentials. The config holds no secrets: service passwords are set in the web UIs, SSH public keys are safe to share. The key comment was changed so it doesn't expose my email.
- Nix installed on my Arch laptop so I can build-test and update the lock file before the server ever sees it.

## 2026-11-22 — Confirmed: devices on Dad's network can reach each other

**Finding:** Devices see each other. He has several routers around the house, all on the same IP range, so they act as one LAN.

**Effect:** The LAN-only plan works: dashboard bookmark, TV playback, and SSH from his PC. No Tailscale-style fallback needed.

**Note:** With several routers, only one should be handing out IPs (DHCP). That's the one where a reservation for the server goes.

## 2026-11-22 — No Tailscale; remote admin via AnyDesk + SSH

**Decision:** Remote admin goes through AnyDesk into Dad's PC, then SSH to the server over his LAN.

**Why:** Tailscale (a private overlay network that works through NAT) would let me SSH directly from home, but it's overkill. AnyDesk is already available and needs no new service or account.

**Trade-offs accepted:**
- Depends on Dad's PC being on and available.
- If a bad config change breaks the server's networking, Dad has to reboot and pick the previous generation at the boot menu.
- Requires devices on his network to reach each other.
- Port 22 is visible on the shared network, so SSH must be key-only.

## 2026-11-22 — Drop Avahi (mDNS); bookmark the IP instead

**Decision:** No `homeserver.local`. Dad bookmarks the server's LAN IP.

**Why:** Dad's network is shared. Shared networks often filter mDNS, and Avahi would announce the box to every device on the network.

**Trade-off:** The bookmark breaks if the IP changes. Mitigated with a DHCP reservation or static IP, plus the IP on the console banner.

## 2026-11-22 — Dad does a few small steps himself

**Decision:** Dad plugs it in, bookmarks the dashboard, and sets up the TV/phone apps. I do the OS install, config, and Jellyfin wizard before handoff.

**Why:** He works in tech, so small steps are fine. Anything that's hard to fix remotely stays on my side.

## 2026-11-22 — Treat the shared network as untrusted

**Decision:** Strong passwords on every service, no open Jellyfin registration, SSH key-only, firewall limited to the service ports.

**Why:** Dad's network is shared, so neighbors could reach anything the server exposes. I likely can't forward ports there (possibly CGNAT, router not his), so nothing is exposed to the internet either.

## Earlier — Core stack and layout

- **NixOS:** whole server declared in one config repo; easy rollback and rebuild on new hardware.
- **Jellyfin + qBittorrent-nox + Homepage dashboard behind nginx:** one URL with buttons, so no ports to remember.
- **Everything under `/srv/media` with a shared `media` group:** the second M.2 can later be mounted there with a single `fileSystems` block and nothing else changes.
- **Auto-upgrade weekly with a 04:00–05:00 reboot window, stable channel, weekly GC:** box maintains itself; rollback covers bad updates.
- **Ryzen 5 3500U (assumed) Vega 8 iGPU:** enables VAAPI hardware transcoding in Jellyfin.
