#!/bin/bash
# One-time toolchain setup for a fresh Ubuntu/Debian machine.
# After this, we can run: bash run_experiment.sh
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "-> system packages"
sudo apt-get update
sudo apt-get install -y cmake nodejs python3-venv python3-pip build-essential git curl

echo "-> rust (rustup) + toolchain 1.88.0"
if ! command -v rustup >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.3 -sSf https://sh.rustup.rs | sh -s -- -y
fi
source "$HOME/.cargo/env" 2>/dev/null || export PATH="$HOME/.cargo/bin:$PATH"
rustup toolchain install 1.88.0
rustup default 1.88.0

echo "-> circom 2.1.6"
if ! command -v circom >/dev/null 2>&1 || ! circom --version 2>/dev/null | grep -q 2.1.6; then
  ( cd /tmp && rm -rf circom-build && git clone https://github.com/iden3/circom.git circom-build \
    && cd circom-build && git checkout v2.1.6 && cargo build --release && cargo install --path circom )
fi

echo "-> git submodules (circomlib)"
( cd "$ROOT" && git submodule update --init --recursive )

echo "-> python venv (jwt libs)"
rm -rf "$ROOT/circuit_setup/.venv"
python3 -m venv "$ROOT/circuit_setup/.venv"
"$ROOT/circuit_setup/.venv/bin/python" -m pip install -q --upgrade pip
"$ROOT/circuit_setup/.venv/bin/python" -m pip install -q python_jwt jwcrypto

echo
echo "setup done."
