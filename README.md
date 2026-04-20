# NixOS Configuration

This repository contains my NixOS system configuration.

## Rebuilding the System

After making changes to the configuration, rebuild and activate with:

```bash
sudo nixos-rebuild switch --flake ~/nixos
```

## Usage

- `nixos-rebuild switch` - Build and activate the new configuration
- `nixos-rebuild test` - Build and activate temporarily (doesn't persist after reboot)
- `nixos-rebuild build-vm` - Build a VM with the configuration

For more options, see the [NixOS manual](https://nixos.org/manual/nixos/stable/).