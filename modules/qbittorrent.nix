{ ... }:

{
  # Password and default save path (/srv/media/downloads) are set in the web UI.
  # Setting them in serverConfig would overwrite UI changes on every restart.
  services.qbittorrent = {
    enable = true;
    group = "media";
    webuiPort = 8080;
    openFirewall = true;
  };

  # Downloads stay group-writable so other media users can move or rename them.
  systemd.services.qbittorrent.serviceConfig.UMask = "0002";
}
