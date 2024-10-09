#!/usr/bin/env bash
set -eou pipefail
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1
fake_hash="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
old_hash="$(command nix eval --raw ..#nuscht-search.pnpmDeps.outputHash)"
sed -i "s|$old_hash|$fake_hash|" frontend.nix
new_hash="$({ command nix build ..#nuscht-search.pnpmDeps || true; } |& grep "got:" | cut -d':' -f2 | sed 's| ||g')"
sed -i "s|$fake_hash|$new_hash|" frontend.nix
