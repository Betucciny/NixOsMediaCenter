{ lib, ... }:

{
  # Web file manager over /srv/media for manual fixes and uploads, port 8085.
  services.filebrowser = {
    enable = true;
    group = "media";
    openFirewall = true;
    settings = {
      address = "0.0.0.0";
      port = 8085;
      root = "/srv/media";
    };
  };

  systemd.services.filebrowser.serviceConfig.UMask = lib.mkForce "0002";
}
