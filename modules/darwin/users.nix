{ lib, ... }:

{
  config.darwinModules = lib.mkAfter [
    ({ pkgs, username, ... }: {
      users.users.${username} = {
        home = "/Users/${username}";
      };
    })
  ];
}
