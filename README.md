# NixOS + macOS Configuration

Multi-platform system configuration using [Nix flakes](https://nixos.wiki/wiki/Flakes), [home-manager](https://github.com/nix-community/home-manager), and [nix-darwin](https://github.com/LnL7/nix-darwin).

## Rebuilding

After making changes to the configuration, rebuild and activate with:

**NixOS (Linux):**
```bash
sudo nixos-rebuild switch --flake ~/nixos
```

**macOS (Darwin):**
```bash
sudo darwin-rebuild switch --flake ~/nixos#darwin
```

## Structure

```
modules/
├── nixos/      # NixOS system modules (audio, boot, desktop, fonts, networking, etc.)
├── darwin/     # macOS system modules (fonts, packages, system, users)
├── home/       # Home Manager modules (window manager, terminal, editor, shell, git, etc.)
├── hosts/      # Host-specific NixOS and Darwin configurations
└── defaults.nix
docs/           # Additional documentation
```

## Tech Stack

- **[nixpkgs](https://github.com/NixOS/nixpkgs)** (unstable) — packages and system modules
- **[home-manager](https://github.com/nix-community/home-manager)** — user-level configuration
- **[nix-darwin](https://github.com/LnL7/nix-darwin)** — macOS system management
- **[flake-parts](https://github.com/hercules-ci/flake-parts)** + **[import-tree](https://github.com/vic/import-tree)** — flake organization