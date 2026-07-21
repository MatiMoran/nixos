{ lib, ... }:

{
  config.homeManager.nixosModules = lib.mkAfter [
    ({ ... }: {
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "application/octet-stream" = "xdg-open";
          "x-scheme-handler/postman" = "Postman";
          "inode/directory" = "thunar";
          "application/pdf" = "brave-browser";
          "image/jpeg" = "brave-browser";
          "application/epub+zip" = "calibre";
          "text/plain" = "nvim";
        };
        associations.added = {
          "image/jpeg" = [ "brave-browser" ];
        };
      };
    })
  ];
}
