{ ... }:

{
  services.jellyfin = {
    enable = true;
    group = "media";
    openFirewall = true; # 8096 + LAN discovery for TV apps
  };

  # VAAPI hardware transcoding on the Ryzen's Vega iGPU (/dev/dri/renderD128).
  hardware.graphics.enable = true;
  users.users.jellyfin.extraGroups = [ "render" "video" ];
}
