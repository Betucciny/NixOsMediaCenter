# Home Server for Dad: Plan

_A NixOS mini PC running Jellyfin and qBittorrent. Rationale lives in [DECISIONS.md](DECISIONS.md), procedures in [RUNBOOK.md](RUNBOOK.md)._

## 1. Goal

A small always-on box Dad plugs into power and ethernet, then uses from a browser or the TV: Jellyfin to watch, qBittorrent to download. I do the critical setup before handoff; he handles small steps.

## 2. Success criteria

- Dad opens one bookmarked address (`http://<server-ip>`) and sees buttons for Watch and Downloads.
- After a power cut, everything comes back on its own.
- The server updates and cleans itself.
- I can fix or roll back remotely: AnyDesk into Dad's PC, then SSH to the server.
- Nothing on the box is usable without a password.
- Adding a second SSD takes minutes and changes nothing else.

## 3. Hardware

| Item      | Spec                                                     |
| --------- | -------------------------------------------------------- |
| CPU       | Ryzen 5 3501U, 8 threads, Vega iGPU (`/dev/dri/renderD128`) |
| RAM       | 8 GB; iGPU reservation to drop from 3 GB to 512M–1G in BIOS |
| Storage   | 256 GB SATA M.2 (slot 1)                                 |
| Expansion | Second M.2 slot, empty                                   |
| Network   | 2× ethernet (target), Wi-Fi in use during setup          |

## 4. Software stack

| Component    | Purpose                                              | Port | Dashboard button |
| ------------ | ---------------------------------------------------- | ---- | ---------------- |
| Dashboard    | Spanish landing page, status dots, storage bar       | 80   | n/a              |
| Jellyfin     | Watch (VAAPI transcoding)                            | 8096 | Ver              |
| Seerr   | Search and request movies/shows                      | 5055 | Pedir            |
| qBittorrent  | Download progress, manual torrents                   | 8080 | Descargas        |
| File Browser | Move, rename, upload files in `/srv/media`           | 8085 | Archivos         |
| Radarr       | Movies: find, import, rename, clean up               | 7878 | Admin            |
| Sonarr       | Shows: find, import, rename, clean up                | 8989 | Admin            |
| Prowlarr     | Torrent site manager for Radarr/Sonarr               | 9696 | Admin            |
| FlareSolverr | Cloudflare helper for Prowlarr                       | 8191 (localhost) | n/a  |
| OpenSSH      | Admin, key-only                                      | 22   | n/a              |

**Download flow:** Pedir → Radarr/Sonarr pick a torrent via Prowlarr → qBittorrent downloads to `/srv/media/downloads` → on completion, hardlinked and renamed into `movies/` or `shows/` → Jellyfin picks it up → torrent and download copy removed after the seeding limit.

## 5. Storage

```
/srv/media/
  movies/
  shows/
  downloads/
```

- Owned by a shared `media` group (Jellyfin, qBittorrent, Radarr, Sonarr, File Browser), umask 0002.
- Downloads and library on the same filesystem, so imports are hardlinks: instant, no extra space while seeding.
- Now: a folder on the 256 GB SSD.
- Later: second M.2 labeled `media`, mounted at `/srv/media` with one `fileSystems` block.
- Storage bar on the dashboard turns orange at 85% and red at 95%.

## 6. Network and access

- **Dashboard:** Dad bookmarks `http://<lan-ip>`.
- **Finding the IP:** shown on the server's console login banner.
- **Remote admin:** AnyDesk into Dad's PC → `ssh` to the server over his LAN.
- **SSH key:** dedicated key pair on Dad's PC, public key in the config.
- **Stable IP:** DHCP reservation if possible, otherwise static IP in the config.
- **Firewall:** only the ports in section 4.

## 7. Security

- SSH key-only, no password login, no root login.
- Strong unique passwords for every web UI (Jellyfin, qBittorrent, Radarr, Sonarr, Prowlarr, File Browser), in my password manager.
- Jellyfin: no open registration, no passwordless users.
- Dad uses a non-admin Jellyfin user (also his Seerr login); I keep admin.
- AnyDesk on Dad's PC behind a strong password.
- Nothing exposed to the internet.

## 8. Maintenance and recovery

- Auto-upgrade weekly, reboots only 04:00–05:00, stable channel.
- Garbage collection weekly, keep 30 days.
- Rollback: pick a previous generation at boot.
- No backups of app state; [RUNBOOK.md](RUNBOOK.md) documents every setting to redo them.

## 9. Config repo

Flake pinned to `nixos-26.05`, public on GitHub at `Betucciny/NixOsMediaCenter`. One host, small modules.

```
flake.nix               # nixpkgs nixos-26.05 → nixosConfigurations.homeserver
flake.lock              # exact nixpkgs version; updated only from my laptop
hosts/homeserver/
  default.nix           # imports, hostname, stateVersion
  hardware-configuration.nix   # copied from the installed server
modules/
  base.nix              # boot, network, timezone, zram, IP banner, flakes
  users.nix             # my user, SSH keys (mine + Dad's PC), SSH hardening
  storage.nix           # /srv/media folders, second-drive mount (commented)
  jellyfin.nix          # Jellyfin + VAAPI
  qbittorrent.nix       # qBittorrent web UI
  arr.nix               # Radarr, Sonarr, Prowlarr, FlareSolverr, Seerr
  filebrowser.nix       # File Browser over /srv/media
  dashboard.nix         # nginx: page, status checks, disk usage timer
  dashboard/index.html  # Spanish page; links follow the current IP
  maintenance.nix       # weekly auto-upgrade from GitHub, GC, store optimise
```

**Tooling on my laptop:** Nix (package manager only, on Arch) to build-test and update `flake.lock`.

**Change flow**

1. Edit on my laptop, test with `nix build .#nixosConfigurations.homeserver.config.system.build.toplevel`.
2. Commit and push.
3. On the server: `sudo nixos-rebuild switch --refresh --flake github:Betucciny/NixOsMediaCenter#homeserver`.
   - At my place: SSH straight in. At Dad's: AnyDesk → his PC → SSH.

**Updates:** `nix flake update` on my laptop, test, push. The server's Sunday 04:00 auto-upgrade builds the latest commit and reboots if needed.

## 10. Rollout phases

**Phase 1: Core, at my place**

1. BIOS: power on after AC loss, Secure Boot off, UEFI boot, UMA frame buffer 512M–1G.
2. Flash the NixOS ISO and install with no desktop.
3. Enable SSH and confirm I can connect.
4. Apply the config from the repo.
5. Jellyfin: wizard, libraries (`movies`, `shows`), VAAPI, Dad's non-admin user.
6. qBittorrent: password, default save path `/srv/media/downloads`, automatic torrent management, Spanish UI.
7. Prowlarr: add torrent sites, FlareSolverr if needed, connect to Radarr and Sonarr.
8. Radarr/Sonarr: root folders, qBittorrent as download client, naming rules, seeding limit + remove completed.
9. Seerr: connect to Jellyfin, Radarr, Sonarr; Spanish.
10. File Browser: admin password, Dad's user.
11. End-to-end test: request a movie and a show, confirm they land renamed in Jellyfin and the torrent is removed after seeding.

**Phase 2: Convenience**

1. Samba share for dragging files in from his PC.
2. Test playback on his TV and phone.
3. Add the second M.2 when ready.

**Phase 3: Nice-to-have**

1. VPN for qBittorrent.
2. Uptime monitoring / alerts.

## 11. Handoff

- Burn-in for a few days at my place, including a forced power cut.
- Dad: plug in power and ethernet, bookmark the dashboard, confirm it works.
- Over AnyDesk: create SSH key on his PC, add to config, confirm SSH works.
- Dad sets up the Jellyfin apps on TV and phone.
- Show him the flow once: Pedir → Solicitar → watch it appear in Ver.
- One-page cheat sheet: URL, what each button does, "unplug 10 seconds if broken".

## 12. Risks

| Risk                                       | Mitigation                                       |
| ------------------------------------------ | ------------------------------------------------ |
| Neighbors reach services                   | Passwords, no open registration, SSH key-only    |
| LAN IP changes                             | DHCP reservation or static IP; IP banner         |
| Dad's PC off when something breaks         | Wait for him; worst case he reboots the server   |
| Bad change kills networking                | Test before switching; old generation at boot    |
| NixOS option names change                  | Pin nixpkgs                                      |
| Disk fills up                              | Second M.2, storage bar warning, seeding limits  |
| Torrent site blocks Prowlarr (Cloudflare)  | FlareSolverr; swap sites                         |
| Bad release grabbed (wrong language, fake) | Quality/language profiles in Radarr/Sonarr       |

## 13. Open questions

1. Which router hands out IPs, and can we set a DHCP reservation on it (or use a static IP)?
2. Exact CPU, and second M.2 slot NVMe or SATA?
3. Which devices will he watch on?
4. Magnet links by hand, or Sonarr/Radarr?
5. VPN for downloads?
6. Samba in phase 1 or 2?
7. Is a router near where the box will sit?

## 14. Next steps

- [x] Get the mini PC ready
- [ ] Answer the open questions
- [ ] Flash the NixOS ISO
- [ ] Install and confirm SSH access
- [ ] Apply the phase 1 config
- [ ] Burn-in and handoff prep
