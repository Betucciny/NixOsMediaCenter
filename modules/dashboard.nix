{ pkgs, ... }:

let
  # Health checks: same-origin URLs the page can poll. Any response other than
  # an nginx 502/504 means the service is up.
  status = name: port: {
    "/status/${name}" = {
      proxyPass = "http://127.0.0.1:${toString port}/";
      extraConfig = ''
        proxy_connect_timeout 2s;
        proxy_read_timeout 3s;
        access_log off;
      '';
    };
  };
in
{
  services.nginx = {
    enable = true;
    virtualHosts.dashboard = {
      default = true;
      root = ./dashboard;
      locations = {
        "= /disk.json" = {
          alias = "/run/dashboard/disk.json";
          extraConfig = "add_header Cache-Control no-store; access_log off;";
        };
      }
      // status "jellyfin" 8096
      // status "jellyseerr" 5055
      // status "qbittorrent" 8080
      // status "filebrowser" 8085
      // status "radarr" 7878
      // status "sonarr" 8989
      // status "prowlarr" 9696;
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 ];

  # Disk usage of /srv/media, written every minute for the storage bar.
  systemd.tmpfiles.rules = [ "d /run/dashboard 0755 root root -" ];

  systemd.services.dashboard-disk = {
    description = "Write /srv/media disk usage for the dashboard";
    path = [ pkgs.coreutils pkgs.gawk ];
    script = ''
      df -B1 --output=size,used,avail /srv/media | tail -n 1 \
        | awk '{ printf "{\"size\":%s,\"used\":%s,\"avail\":%s}\n", $1, $2, $3 }' \
        > /run/dashboard/disk.json.tmp
      mv /run/dashboard/disk.json.tmp /run/dashboard/disk.json
    '';
    serviceConfig.Type = "oneshot";
  };

  systemd.timers.dashboard-disk = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnBootSec = "30s"; OnUnitActiveSec = "1min"; };
  };
}
