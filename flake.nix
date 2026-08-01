{
  description = "Multi-platform NixOS + macOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    import-tree.url = "github:vic/import-tree";

    # Pinned to release tag v2026.7.30 (v0.19.1). Newer revs on main are
    # broken for the nix build — the 2026-07-31 js/deps batch regenerated
    # package-lock.json dropping integrity for web/node_modules/@nous-research/ui
    # (ENOTCACHED in the offline npm install). Earlier revs (e.g. 745d1383)
    # shipped hermes_state.py without hermes_state_common in py-modules,
    # breaking the gateway at runtime.
    hermes-agent.url = "github:NousResearch/hermes-agent/cc4cab2f592e60a197e796506de9168f74baf3ea";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
