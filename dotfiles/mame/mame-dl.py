#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3 aria2

import argparse
import functools
import os
import re
import subprocess
import sys
import tempfile
import zipfile
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import quote

print = functools.partial(print, flush=True)

TRACKERS_LIST = [
    "udp://tracker.opentrackr.org:1337/announce",
    "udp://exodus.desync.com:6969/announce",
]
TRACKERS = ",".join(TRACKERS_LIST)

BT_CACHE_DIR = Path.home() / ".local/share/qBittorrent/BT_backup"
MAME_DIR = Path.home() / ".mame"
ROMS_DIR = MAME_DIR / "roms"
SNAP_DIR = MAME_DIR / "snap"
TITLES_DIR = MAME_DIR / "titles"
ARTWORK_DIR = MAME_DIR / "artwork"
GAMES_FILE = MAME_DIR / "games.txt"


@dataclass(frozen=True)
class Torrent:
    name: str
    info_hash: str
    size: int

    @property
    def magnet(self) -> str:
        params = (
            [f"xt=urn:btih:{self.info_hash}", f"dn={quote(self.name)}",
             f"xl={self.size}"]
            + [f"tr={quote(t, safe='')}" for t in TRACKERS_LIST]
        )
        return "magnet:?" + "&".join(params)

    @property
    def cache_path(self) -> Path:
        return BT_CACHE_DIR / f"{self.info_hash}.torrent"


ROMS_TORRENT = Torrent(
    name="MAME 0.288 ROMs (non-merged)",
    info_hash="d4d698e5398a83bd762d8137eb196c510a86c23e",
    size=162840563456,
)

EXTRAS_TORRENT = Torrent(
    name="MAME 0.288 EXTRAs",
    info_hash="1c89382ab9b2fc21712ab20e194a0f7a9ee0bace",
    size=70542784852,
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


def get_torrent_file(torrent: Torrent) -> Path:
    cache = torrent.cache_path
    if cache.exists():
        return cache
    print(f"  Torrent '{torrent.name}' not cached. Fetching metadata from DHT...")
    subprocess.run(
        ["aria2c", "--bt-metadata-only=true",
         "--bt-save-metadata=true",
         f"--dir={cache.parent}",
         torrent.magnet],
        timeout=180
    )
    if not cache.exists():
        print("Error: Could not fetch torrent metadata")
        sys.exit(1)
    return cache


def list_torrent_files(torrent_path: Path) -> dict[int, str]:
    result = subprocess.run(
        ["aria2c", "--show-files", str(torrent_path)],
        capture_output=True, text=True, timeout=30
    )
    output = result.stdout + result.stderr
    files: dict[int, str] = {}
    for line in output.split("\n"):
        m = re.match(r'\s*(\d+)\|(.+\.zip)$', line)
        if m:
            files[int(m.group(1))] = m.group(2)
    return files


def download_files(torrent_path: Path, dest: Path, pairs: list[tuple[int, str]]):
    dest.mkdir(parents=True, exist_ok=True)
    select_str = ",".join(str(idx) for idx, _ in pairs)
    index_out = [f"--index-out={idx}={name}" for idx, name in pairs]
    cmd = (["aria2c", f"--select-file={select_str}"] + index_out +
           [f"--dir={dest}", "--seed-time=0",
            "--summary-interval=5",
            "--bt-tracker", TRACKERS,
            str(torrent_path)])
    subprocess.run(cmd)


def download_bundle(torrent_path: Path, dest: Path, idx: int, name: str) -> Path:
    download_files(torrent_path, dest, [(idx, name)])
    return dest / name


def extract_missing(bundle: Path, dest: Path, wanted: list[str]) -> list[str]:
    dest.mkdir(parents=True, exist_ok=True)
    missing: list[str] = []
    with zipfile.ZipFile(bundle) as zf:
        names = set(zf.namelist())
        for name in wanted:
            if name in names:
                zf.extract(name, dest)
                print(f"  ✓ {name} -> {dest}")
            else:
                print(f"  ✗ {name} -> not in bundle")
                missing.append(name)
    return missing


def is_rom_verified(rom_name: str) -> bool:
    target = ROMS_DIR / f"{rom_name}.zip"
    if not target.exists():
        return False
    result = subprocess.run(
        ["mame", "-rompath", str(ROMS_DIR), "-verifyroms", rom_name],
        capture_output=True, text=True, timeout=120
    )
    return "is good" in result.stdout


def download_roms(roms: list[str], not_found: list[str]):
    print(f"\n[2/5] Downloading ROMs...")
    print(f"  Target: {ROMS_DIR}")
    torrent_file = get_torrent_file(ROMS_TORRENT)
    file_map = list_torrent_files(torrent_file)
    by_basename = {os.path.basename(path): idx for idx, path in file_map.items()}

    pairs: list[tuple[int, str]] = []
    for rom in roms:
        target = f"{rom}.zip"
        idx = by_basename.get(target)
        if idx is None:
            print(f"  ✗ {target} -> not in torrent set")
            not_found.append(rom)
            continue
        if is_rom_verified(rom):
            print(f"  ✓ {target} already downloaded and verified, skipping")
            continue
        print(f"  ✓ {target} -> index {idx}")
        pairs.append((idx, target))

    if not pairs:
        print("  All ROMs already downloaded and verified.")
        return
    download_files(torrent_file, ROMS_DIR, pairs)
    print(f"  Downloaded {len(pairs)} file(s) to {ROMS_DIR}")


def download_snapshots(roms: list[str], missing_report: dict[str, list[str]]):
    print(f"\n[3/5] Downloading snapshots...")
    print(f"  Target: {SNAP_DIR}")
    missing = [rom for rom in roms if not (SNAP_DIR / f"{rom}.png").exists()]
    if not missing:
        print("  All snapshots already present, skipping.")
        return

    torrent_file = get_torrent_file(EXTRAS_TORRENT)
    file_map = list_torrent_files(torrent_file)
    idx = next((i for i, p in file_map.items()
                if os.path.basename(p) == "snap.zip"), None)
    if idx is None:
        print("  ✗ snap.zip not found in EXTRAs set")
        missing_report["snapshots"] = missing
        return

    print(f"  Downloading snap.zip ({len(missing)} snapshot(s) missing)...")
    with tempfile.TemporaryDirectory(prefix="mame-dl-") as tmp:
        bundle = download_bundle(torrent_file, Path(tmp), idx, "snap.zip")
        if not bundle.exists():
            print("  ✗ Error downloading snap.zip")
            missing_report["snapshots"] = missing
            return
        not_in_set = extract_missing(
            bundle, SNAP_DIR, [f"{rom}.png" for rom in missing]
        )
    if not_in_set:
        missing_report["snapshots"] = [
            rom for rom, png in zip(missing, [f"{r}.png" for r in missing])
            if png in not_in_set
        ]


def download_titles(roms: list[str], missing_report: dict[str, list[str]]):
    print(f"\n[4/5] Downloading titles...")
    print(f"  Target: {TITLES_DIR}")
    missing = [rom for rom in roms if not (TITLES_DIR / f"{rom}.png").exists()]
    if not missing:
        print("  All titles already present, skipping.")
        return

    torrent_file = get_torrent_file(EXTRAS_TORRENT)
    file_map = list_torrent_files(torrent_file)
    idx = next((i for i, p in file_map.items()
                if os.path.basename(p) == "titles.zip"), None)
    if idx is None:
        print("  ✗ titles.zip not found in EXTRAs set")
        missing_report["titles"] = missing
        return

    print(f"  Downloading titles.zip ({len(missing)} title(s) missing)...")
    with tempfile.TemporaryDirectory(prefix="mame-dl-") as tmp:
        bundle = download_bundle(torrent_file, Path(tmp), idx, "titles.zip")
        if not bundle.exists():
            print("  ✗ Error downloading titles.zip")
            missing_report["titles"] = missing
            return
        not_in_set = extract_missing(
            bundle, TITLES_DIR, [f"{rom}.png" for rom in missing]
        )
    if not_in_set:
        missing_report["titles"] = [
            rom for rom, png in zip(missing, [f"{r}.png" for r in missing])
            if png in not_in_set
        ]


def download_artwork(roms: list[str], missing_report: dict[str, list[str]]):
    print(f"\n[5/5] Downloading artwork...")
    print(f"  Target: {ARTWORK_DIR}")
    missing = [rom for rom in roms if not (ARTWORK_DIR / f"{rom}.zip").exists()]
    if not missing:
        print("  All artwork already present, skipping.")
        return

    torrent_file = get_torrent_file(EXTRAS_TORRENT)
    file_map = list_torrent_files(torrent_file)
    artwork_by_basename: dict[str, int] = {}
    for idx, path in file_map.items():
        if "artwork" in Path(path).parts:
            artwork_by_basename[os.path.basename(path)] = idx

    pairs: list[tuple[int, str]] = []
    no_artwork: list[str] = []
    for rom in missing:
        target = f"{rom}.zip"
        idx = artwork_by_basename.get(target)
        if idx is None:
            print(f"  ✗ {target} -> no artwork in set")
            no_artwork.append(rom)
            continue
        print(f"  ✓ {target} -> index {idx}")
        pairs.append((idx, target))

    if not pairs:
        print("  No artwork available in the EXTRAs set for these games.")
        if no_artwork:
            missing_report["artwork"] = no_artwork
        return

    ARTWORK_DIR.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="mame-dl-") as tmp:
        download_files(torrent_file, Path(tmp), pairs)
        for idx, name in pairs:
            src = Path(tmp) / name
            if src.exists():
                os.replace(src, ARTWORK_DIR / name)
    print(f"  Downloaded {len(pairs)} file(s) to {ARTWORK_DIR}")
    if no_artwork:
        missing_report["artwork"] = no_artwork
    if no_artwork:
        missing_report["artwork"] = no_artwork


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Download MAME ROMs, snapshots, titles and artwork "
            "for the games listed in the input file."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Input file format (one per line):\n"
            "  Sunset Riders\n"
            "  ssriders          # exact ROM name also works\n"
            "  # this is a comment\n"
            "\n"
            "ROMs come from the non-merged set; snapshots, titles and "
            "artwork from the EXTRAs set. Already downloaded files are "
            "skipped. Snapshots/titles bundles are deleted after "
            "extracting the wanted files."
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

    print("[1/5] Looking up game names in MAME...")
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

    download_roms(roms, not_found)

    missing_report: dict[str, list[str]] = {}
    download_snapshots(roms, missing_report)
    download_titles(roms, missing_report)
    download_artwork(roms, missing_report)

    print(f"\nDone!")

    if not_found or missing_report:
        print()
    if not_found:
        print(f"Not found ({len(not_found)}):")
        for n in not_found:
            print(f"  - {n}")
    for label, items in missing_report.items():
        if items:
            print(f"\n{label.capitalize()} not available in the EXTRAs set "
                  f"({len(items)}):")
            for i in items:
                print(f"  - {i}")


if __name__ == "__main__":
    main()
