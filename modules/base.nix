{ pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  time.timeZone = "America/Mexico_City";
  i18n.defaultLocale = "en_US.UTF-8";

  zramSwap.enable = true;

  # Shown above the console login: makes the server's IP easy to find.
  # \4 is expanded by agetty to the current IPv4 address.
  services.getty.helpLine = ''
    Dashboard: http://\4/
  '';

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [ git vim htop ];
}
