{
  description = "Home media server for Dad";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { nixpkgs, ... }: {
    nixosConfigurations.homeserver = nixpkgs.lib.nixosSystem {
      modules = [ ./hosts/homeserver ];
    };
  };
}
