#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3 aria2

import subprocess
import sys
import os
import re
import argparse
import functools
from pathlib import Path

print = functools.partial(print, flush=True)

TORRENT_HASH = "d4d698e5398a83bd762d8137eb196c510a86c23e"
TORRENT_CACHE = Path.home() / ".local/share/qBittorrent/BT_backup" / f"{TORRENT_HASH}.torrent"
ROMS_DIR = Path.home() / ".mame" / "roms"
GAMES_FILE = Path.home() / ".mame" / "games.txt"

MAGNET = (
    "magnet:?xt=urn:btih:d4d698e5398a83bd762d8137eb196c510a86c23e"
    "&dn=MAME%200.288%20ROMs%20%28non-merged%29"
    "&xl=162840563456"
    "&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337%2Fannounce"
    "&tr=udp%3A%2F%2Fexodus.desync.com%3A6969%2Fannounce"
)


def read_games(filepath: Path) -> list[str]:
    games = []
    with open(filepath) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            games.append(line)
    return games


def get_mame_list() -> list[str]:
    result = subprocess.run(
        ["mame", "-listfull"],
        capture_output=True, text=True, timeout=120
    )
    if result.returncode != 0:
        print("Error: mame -listfull failed")
        sys.exit(1)
    return [l for l in result.stdout.split("\n") if l.strip()]


def is_clone(rom_name: str) -> bool:
    result = subprocess.run(
        ["mame", "-listclones", rom_name],
        capture_output=True, text=True, timeout=30
    )
    for line in result.stdout.split("\n"):
        if rom_name in line and "Clone of:" in line:
            return True
    return False


def lookup_rom(game_name: str, mame_list: list[str]) -> str | None:
    game_lower = game_name.lower().strip()

    for line in mame_list:
        if line.split()[0].lower() == game_lower:
            return line.split()[0]

    skip_keywords = ["bootleg", "scrambled", "hack", "unofficial",
                     "prototype", "pirate"]

    candidates = []
    for line in mame_list:
        rom = line.split()[0]
        parts = line.split('"', 2)
        if len(parts) < 2:
            continue
        desc = parts[1].lower()
        if desc.startswith(game_lower):
            is_bootleg = any(k in desc for k in skip_keywords)
            candidates.append((is_bootleg, len(rom), rom))

    if not candidates:
        for line in mame_list:
            rom = line.split()[0]
            if game_lower in line.lower():
                candidates.append((False, len(rom), rom))

    if not candidates:
        return None

    candidates.sort(key=lambda x: (x[0], x[1]))
    best = candidates[0][2]
    for _, _, rom in candidates:
        if not is_clone(rom):
            return rom
    return best


def get_torrent_file() -> Path:
    if TORRENT_CACHE.exists():
        return TORRENT_CACHE
    print("  Torrent not cached. Fetching metadata from DHT...")
    subprocess.run(
        ["aria2c", "--bt-metadata-only=true",
         "--bt-save-metadata=true",
         f"--dir={TORRENT_CACHE.parent}",
         MAGNET],
        timeout=120
    )
    if not TORRENT_CACHE.exists():
        print("Error: Could not fetch torrent metadata")
        sys.exit(1)
    return TORRENT_CACHE


def list_torrent_files(torrent_path: Path) -> dict[str, int]:
    result = subprocess.run(
        ["aria2c", "--show-files", str(torrent_path)],
        capture_output=True, text=True, timeout=30
    )
    output = result.stdout + result.stderr
    files: dict[str, int] = {}
    for line in output.split("\n"):
        m = re.match(r'\s*(\d+)\|(.+\.zip)$', line)
        if m:
            idx = int(m.group(1))
            basename = os.path.basename(m.group(2))
            files[basename] = idx
    return files


TRACKERS = (
    "udp://tracker.opentrackr.org:1337/announce,"
    "udp://exodus.desync.com:6969/announce"
)


def is_rom_verified(rom_name: str) -> bool:
    target = ROMS_DIR / f"{rom_name}.zip"
    if not target.exists():
        return False
    result = subprocess.run(
        ["mame", "-rompath", str(ROMS_DIR), "-verifyroms", rom_name],
        capture_output=True, text=True, timeout=120
    )
    return "is good" in result.stdout


def download(torrent_path: Path, indices: list[int], roms: list[str]):
    to_download = []
    for idx, rom in zip(indices, roms):
        if is_rom_verified(rom):
            print(f"  - {rom}.zip already downloaded and verified, skipping")
        else:
            to_download.append((idx, rom))

    if not to_download:
        print("  All files already downloaded and verified.")
        return

    select_str = ",".join(str(idx) for idx, _ in to_download)
    index_out = [f"--index-out={idx}={rom}.zip"
                 for idx, rom in to_download]
    cmd = (["aria2c", f"--select-file={select_str}"] + index_out +
           [f"--dir={ROMS_DIR}", "--seed-time=0",
            "--summary-interval=5",
            "--bt-tracker", TRACKERS,
            str(torrent_path)])
    subprocess.run(cmd)


def main():
    parser = argparse.ArgumentParser(
        description="Download MAME ROMs from non-merged torrent",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Input file format (one per line):\n"
            "  Sunset Riders\n"
            "  ssriders          # exact ROM name also works\n"
            "  # this is a comment\n"
        )
    )
    parser.add_argument(
        "file", nargs="?", default=str(GAMES_FILE),
        help=f"File with game names (default: {GAMES_FILE})"
    )
    args = parser.parse_args()

    games_file = Path(args.file)
    if not games_file.exists():
        print(f"File not found: {games_file}")
        sys.exit(1)

    games = read_games(games_file)
    if not games:
        print("No games specified (file is empty or all comments).")
        sys.exit(1)

    print(f"Reading {len(games)} game(s) from {games_file}\n")

    print("[1/3] Looking up game names in MAME...")
    mame_list = get_mame_list()
    roms: list[str] = []
    not_found: list[str] = []
    for game in games:
        rom = lookup_rom(game, mame_list)
        if rom:
            print(f"  ✓ '{game}' -> {rom}.zip")
            roms.append(rom)
        else:
            print(f"  ✗ '{game}' -> not found")
            not_found.append(game)

    if not roms:
        print("\nNo games found in MAME. Exiting.")
        sys.exit(1)

    print(f"\n[2/3] Scanning torrent for matching files...")
    torrent_file = get_torrent_file()
    file_map = list_torrent_files(torrent_file)

    indices: list[int] = []
    matched: list[str] = []
    for rom in roms:
        target = f"{rom}.zip"
        idx = file_map.get(target)
        if idx is not None:
            print(f"  ✓ {target} -> index {idx}")
            indices.append(idx)
            matched.append(rom)
        else:
            print(f"  ✗ {target} -> not in torrent set")
            not_found.append(rom)

    if not indices:
        print("\nNo files to download. Exiting.")
        sys.exit(1)

    print(f"\n[3/3] Downloading {len(indices)} file(s)...")
    print(f"  Target: {ROMS_DIR}")
    download(torrent_file, indices, matched)

    print(f"\nDone! {len(indices)} file(s) saved to {ROMS_DIR}")

    if not_found:
        print(f"\nNot found ({len(not_found)}):")
        for n in not_found:
            print(f"  - {n}")


if __name__ == "__main__":
    main()
