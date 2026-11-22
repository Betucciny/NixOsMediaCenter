{ lib, ... }:

{
  # Everything media-related lives under /srv/media, owned by the media group.
  # setgid (2775) keeps new files in the media group.
  systemd.tmpfiles.rules = [
    "d /srv/media           2775 root media - -"
    "d /srv/media/movies    2775 root media - -"
    "d /srv/media/shows     2775 root media - -"
    "d /srv/media/downloads 2775 root media - -"
  ];

  # Second drive: format it as ext4 with label "media", copy existing files over,
  # then uncomment both blocks (see RUNBOOK.md, "Add the second M.2").
  # fileSystems."/srv/media" = {
  #   device = "/dev/disk/by-label/media";
  #   fsType = "ext4";
  #   options = [ "nofail" ];
  # };
  #
  # If the drive fails to mount, /srv/media is an empty folder on the OS disk:
  # don't let anything download into it and fill the 256 GB SSD.
  # systemd.services = lib.genAttrs
  #   [ "jellyfin" "qbittorrent" "radarr" "sonarr" "bazarr" "filebrowser" ]
  #   (_: { unitConfig.RequiresMountsFor = [ "/srv/media" ]; });
}
