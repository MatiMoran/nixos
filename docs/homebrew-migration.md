# Homebrew → Nix Migration

Inventario completo de paquetes actuales en Homebrew, categorizados para migración futura a nixpkgs.

## Estado

- **Migrado a Nix**: Alacritty (`programs.alacritty` via home-manager)
- **Pendiente**: todo lo demás (listado abajo)

---

## Formulae — disponibles en nixpkgs

Agregar a `hosts/darwin/default.nix` (`environment.systemPackages`) o `home/darwin.nix` (`home.packages`).

| Homebrew | nixpkgs |
|---|---|
| `bat` | `bat` (ya en darwin config) |
| `fd` | `fd` (ya en darwin config) |
| `fzf` | `fzf` (ya en darwin config) |
| `ripgrep` | `ripgrep` (ya en darwin config) |
| `tmux` | `tmux` (ya en darwin config) |
| `git` | `git` (ya en darwin config) |
| `zoxide` | `zoxide` (ya en darwin config) |
| `gh` | `gh` |
| `git-filter-repo` | `git-filter-repo` |
| `gnu-sed` | `gnused` |
| `tldr` | `tldr` |
| `pandoc` | `pandoc` |
| `pre-commit` | `pre-commit` |
| `stow` | `stow` |
| `rsync` | `rsync` |
| `curl` | `curl` |
| `awscli` | `awscli2` |
| `pyenv` | `pyenv` |
| `pipx` | `pipx` |
| `node` | `nodejs_22` |
| `python@3.13` | `python313` |
| `colima` | `colima` |
| `docker` | `docker` |
| `docker-compose` | `docker-compose` |
| `docker-credential-helper` | `docker-credential-helpers` |
| `lima` | `lima` |
| `podman` | `podman` |
| `ffmpeg` | `ffmpeg` |
| `kanata` | `kanata` |

### Librerías de soporte (generalmente no hace falta declararlas — nixpkgs las trae como dependencias)
`brotli`, `c-ares`, `ca-certificates`, `fmt`, `gdbm`, `gmp`, `icu4c@78`, `libgit2`, `libuv`,
`lz4`, `ncurses`, `oniguruma`, `openssl@3`, `pcre2`, `readline`, `sqlite`, `xz`, `xxhash`,
`zlib`, `zstd`, `libevent`, `libnghttp2`, `libssh2`, `libyaml`, `mpdecimal`, `utf8proc`, etc.

---

## Casks — disponibles en nixpkgs (unfree)

Requieren `nixpkgs.config.allowUnfree = true` en `hosts/darwin/default.nix`.

| Homebrew cask | nixpkgs |
|---|---|
| `alacritty` | **Ya migrado** via `programs.alacritty` |
| `gimp` | `gimp` |
| `keepassxc` | `keepassxc` |
| `obsidian` | `obsidian` (unfree) |
| `vlc` | `vlc` (unfree) |
| `visual-studio-code` | `vscode` (unfree) |
| `gcloud-cli` | `google-cloud-sdk` |
| `flameshot` | `flameshot` |

---

## Casks — NO disponibles en nixpkgs (quedan en Homebrew o instalación manual)

Estos paquetes vienen de taps personalizados o son muy recientes para nixpkgs.

| Cask/Formula | Origen | Alternativa |
|---|---|---|
| `aerospace` | `nikitabobko/tap` | Verificar nixpkgs; si no está, usar `homebrew.casks` en nix-darwin |
| `claude-code` | Anthropic | Instalar via `npm install -g @anthropic-ai/claude-code` o mantener en Homebrew |
| `codex` | OpenAI | Instalar manualmente |
| `gstreamer-runtime` | — | Verificar nixpkgs (`gst_all_1`) |
| `acli` | `atlassian/acli` | Sin equivalente en nixpkgs |
| `herdr` | `vjeantet/tap` | Sin equivalente en nixpkgs |
| `alerter` | `asmvik/formulae` | Sin equivalente en nixpkgs; alternativa: `terminal-notifier` |

---

## Python — múltiples versiones

Homebrew tiene instalado `python@3.9` hasta `python@3.14` (vía pyenv).
En Nix, la recomendación es usar `devShells` por proyecto con la versión exacta, o mantener `pyenv` + `nixpkgs#pyenv`.

---

## Próximos pasos sugeridos

1. Agregar al darwin config los CLI tools del primer bloque (gh, gnu-sed, tldr, etc.)
2. Habilitar `nixpkgs.config.allowUnfree = true` y agregar GUI apps (keepassxc, obsidian, vlc)
3. Para `aerospace`: revisar si `pkgs.aerospace` ya existe en nixpkgs-unstable
4. Para residuales sin nixpkgs: declarar en `homebrew.casks`/`homebrew.brews` de nix-darwin (requiere agregar input `nix-homebrew`)
