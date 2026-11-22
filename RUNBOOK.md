# Runbook

How to rebuild the server from nothing, and how to do routine tasks. App settings are not backed up; this file is the reference to redo them.

Server: `betucciny@<ip>` (at my place: `192.168.1.172`). Repo: this one.

---

## A. Rebuild from scratch

### 1. BIOS (monitor + keyboard)

- Restore on AC power loss → **Power On**
- Secure Boot → **Disabled**
- Boot mode → **UEFI**
- UMA Frame Buffer Size → **512M–1G** (default reserves 3 GB of RAM)

### 2. Install NixOS

1. Flash the graphical ISO (`nixos-graphical-26.05…iso`):
   `sudo dd if=<iso> of=/dev/sdX bs=4M status=progress conv=fsync` (whole disk, not a partition; unmount first).
2. Boot the USB, first menu entry.
3. No ethernet? Super → `terminal`: `nmcli device wifi connect "SSID" password "…"`
4. Installer (Super → `install`; Tab / Space / Enter):
   - Login name **`betucciny`** (must match `modules/users.nix`), hostname `homeserver`
   - Strong password, no autologin, same password for admin
   - **No desktop**, no unfree
   - Erase disk, **ext4**, **no swap**
5. Reboot, remove USB, log in.

### 3. First SSH access

On the server:
```bash
nmcli device wifi connect "SSID" password "…"      # if on Wi-Fi
nix-shell -p vim --run "sudo vim /etc/nixos/configuration.nix"
#   add: services.openssh.enable = true;
sudo nixos-rebuild switch
ip -4 a | grep inet
```
On the laptop:
```bash
ssh-copy-id betucciny@<ip>
```

### 4. Apply the config

```bash
# laptop: bring the new hardware file into the repo
scp betucciny@<ip>:/etc/nixos/hardware-configuration.nix hosts/homeserver/
git add -A && git commit -m "New hardware config" && git push

# server
sudo nixos-rebuild switch --refresh --flake github:Betucciny/NixOsMediaCenter#homeserver
```
Not pushed yet? Copy the repo over and use `--flake path:/home/betucciny/NixOsMediaCenter#homeserver`.

Check: `systemctl --failed` is empty, `http://<ip>` shows the dashboard.

### 5. App setup (in this order)

#### Jellyfin — `http://<ip>:8096`

- Wizard: admin user (password manager), allow remote connections **on** (LAN).
- Libraries:

  | Name      | Type   | Folder              |
  | --------- | ------ | ------------------- |
  | Películas | Movies | `/srv/media/movies` |
  | Series    | Shows  | `/srv/media/shows`  |

  In each: metadata language **Spanish**, country **Mexico**, real-time monitoring **on**, trickplay extraction **off**, chapter images off, prefer embedded titles off. Movies: automatically add to collection **on**. Rest default.
- Dashboard → Playback → Transcoding: **VAAPI**, device `/dev/dri/renderD128`, hardware decoding **H264, HEVC, VC1, VP9** (no AV1).
- Users → add Dad, **not admin** (also his Seerr login).

#### qBittorrent — `http://<ip>:8080`

- Temporary password (changes on every restart until set): `journalctl -u qbittorrent | grep -i password`, user `admin`.
- Tools → Options:
  - WebUI: own username + password, language Español.
  - Downloads: default save path `/srv/media/downloads`, default torrent management mode **Automatic**.
  - BitTorrent: seeding limit (ratio 2.0 or 7 days).

#### Prowlarr — `http://<ip>:9696`

_To fill in during setup._

#### Radarr — `http://<ip>:7878` / Sonarr — `http://<ip>:8989`

_To fill in during setup._

#### Seerr — `http://<ip>:5055`

_To fill in during setup._

#### File Browser — `http://<ip>:8085`

_To fill in during setup._

### 6. Verify

Request a movie in Seerr → it downloads → appears renamed in Jellyfin → torrent removed after the seeding limit.

---

## B. Routine tasks

| Task | Command / where |
| --- | --- |
| Deploy a change | laptop: commit + push → server: `sudo nixos-rebuild switch --refresh --flake github:Betucciny/NixOsMediaCenter#homeserver` |
| Test a change before deploying | laptop: `nix build .#nixosConfigurations.homeserver.config.system.build.toplevel` |
| Update packages | laptop: `nix flake update` → test → push (server's Sunday 04:00 auto-upgrade picks it up) |
| Roll back | server: `sudo nixos-rebuild switch --rollback`, or pick an older generation in the boot menu |
| Service status | `systemctl --failed`; `systemctl status <name>`; `journalctl -u <name> -e` |
| Find the server's IP | Console login banner, router device list, or `ip -4 a` |
| Remote access at Dad's | AnyDesk → his PC → `ssh betucciny@<ip>` |
| Free space | Dashboard storage bar, or `df -h /srv/media` |

### Add the second M.2

```bash
lsblk                                   # find the new disk, e.g. /dev/sdb or /dev/nvme0n1
sudo mkfs.ext4 -L media /dev/<disk>
sudo mount /dev/disk/by-label/media /mnt
sudo systemctl stop jellyfin qbittorrent radarr sonarr filebrowser
sudo rsync -aH /srv/media/ /mnt/        # -H keeps hardlinks
sudo umount /mnt
```
Uncomment the `fileSystems."/srv/media"` block in `modules/storage.nix`, deploy, reboot. Check `df -h /srv/media` shows the new disk, then delete the old copy from the root disk (mount `/dev/sda2` elsewhere to reach the hidden folder).
