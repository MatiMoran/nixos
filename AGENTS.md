# NixOS Build Commands

```bash
# Rebuild and switch to new configuration
sudo nixos-rebuild switch --flake ~/nixos

# Update flake inputs (nixpkgs) to latest
nix flake update ~/nixos
```
