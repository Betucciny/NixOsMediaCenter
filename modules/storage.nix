{ ... }:

{
  # Everything media-related lives under /srv/media, owned by the media group.
  # setgid (2775) keeps new files in the media group.
  systemd.tmpfiles.rules = [
    "d /srv/media           2775 root media - -"
    "d /srv/media/movies    2775 root media - -"
    "d /srv/media/shows     2775 root media - -"
    "d /srv/media/downloads 2775 root media - -"
  ];

  # Second M.2: format it as ext4 with label "media", copy existing files over,
  # then uncomment this block.
  # fileSystems."/srv/media" = {
  #   device = "/dev/disk/by-label/media";
  #   fsType = "ext4";
  #   options = [ "nofail" ];
  # };
}
