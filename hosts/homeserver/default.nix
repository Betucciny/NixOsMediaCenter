{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/users.nix
    ../../modules/storage.nix
    ../../modules/jellyfin.nix
    ../../modules/qbittorrent.nix
    ../../modules/arr.nix
    ../../modules/filebrowser.nix
    ../../modules/dashboard.nix
    ../../modules/maintenance.nix
  ];

  networking.hostName = "homeserver";

  # Set at install time. Never change it, even after upgrading NixOS.
  system.stateVersion = "26.05";
}
