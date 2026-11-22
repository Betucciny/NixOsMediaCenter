{ ... }:

{
  # Weekly: pull the latest commit of this repo from GitHub and switch to it.
  # flake.lock is only updated from my laptop, so the server runs what I tested.
  system.autoUpgrade = {
    enable = true;
    flake = "github:Betucciny/NixOsMediaCenter#homeserver";
    dates = "Sun 04:00";
    allowReboot = true;
    rebootWindow = { lower = "04:00"; upper = "05:00"; };
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.settings.auto-optimise-store = true;
}
