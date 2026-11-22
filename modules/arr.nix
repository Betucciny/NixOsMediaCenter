{ ... }:

{
  # Automation: request -> search -> download -> rename + hardlink into the library.
  # Downloads and library share /srv/media (one filesystem), so imports are
  # instant hardlinks and torrents keep seeding until their limit.

  services.radarr = {        # movies, port 7878
    enable = true;
    group = "media";
    openFirewall = true;
  };

  services.sonarr = {        # shows, port 8989
    enable = true;
    group = "media";
    openFirewall = true;
  };

  services.prowlarr = {      # torrent site manager, port 9696
    enable = true;
    openFirewall = true;
  };

  services.flaresolverr = {  # Cloudflare helper for Prowlarr, localhost:8191
    enable = true;
  };

  services.jellyseerr = {    # request page for Dad, port 5055
    enable = true;
    openFirewall = true;
  };

  # Files created by Radarr/Sonarr stay group-writable for the media group.
  systemd.services.radarr.serviceConfig.UMask = "0002";
  systemd.services.sonarr.serviceConfig.UMask = "0002";
}
