{ lib, ... }:

{
  config.nixosModules = lib.mkAfter [
    ({ pkgs, username, ... }: {
      users.groups.uinput = {};
      users.users.${username} = {
        isNormalUser = true;
        description = username;
        extraGroups = [ "networkmanager" "wheel" "input" "uinput" ];
        # "hermes" — disabled along with hermes-agent (see modules/nixos/hermes.nix)
        packages = with pkgs; [];
      };
      services.getty.autologinUser = username;
    })
  ];
}
