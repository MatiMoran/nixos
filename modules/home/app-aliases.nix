{ lib, ... }:

{
  config.homeManager.darwinModules = lib.mkAfter [
    ({ lib, ... }: {
      home.activation.aliasApplications = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        src="$HOME/Applications/Home Manager Apps"
        dst="$HOME/Applications/Nix Apps"

        $DRY_RUN_CMD rm -rf "$dst"
        $DRY_RUN_CMD mkdir -p "$dst"

        if [ -d "$src" ]; then
          for app in "$src"/*.app; do
            [ -e "$app" ] || continue
            app_name=$(basename "$app")
            $DRY_RUN_CMD osascript -e "
              tell application \"Finder\"
                make alias file to POSIX file \"$app\" at POSIX file \"$dst\"
                set name of result to \"$app_name\"
              end tell
            " 2>/dev/null || true
          done
        fi
      '';
    })
  ];
}
