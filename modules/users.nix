{ ... }:

let
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINhOr6G/eg+B5/55jYjShapxuBZTzyCmyEI9HhSDvWnC betucciny-laptop"
    # Dad's PC: add its public key here at handoff.
  ];
in
{
  users.groups.media = { };

  users.users.betucciny = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "media" ];
    openssh.authorizedKeys.keys = sshKeys;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
