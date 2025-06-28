#!/usr/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.
#

set -e
# set -x

SECONDS=0

# Check for "trim" argument to have script clean extraneous artifacts
do_trim=false; for arg in "$@"; do [[ "$arg" == "trim" ]] && do_trim=true && break; done

green() { echo -e "\033[0;32m$1\033[0m"; }

# Enable glob pattern matching
shopt -s extglob

RELEASE_FLAG="--release"

git submodule update --init --recursive

# Circuit setup
# Generates circom circuits and artifacts in circuit_setup/generated_files/
# Final output is copied to creds/test-vectors/[mdl1, rs256, rs256-sd, rs256-db]
# The setup scripts are run in parallel for each circuit type to take advantage of multiple CPU cores
#   as circuit generation is CPU intensive but single-threaded.
# rm -rf circuit_setup/generated_files/!(README.md) creds/test-vectors/!(README.md)
cd circuit_setup/scripts
./run_setup.sh mdl1 &
./run_setup.sh rs256 &
./run_setup.sh rs256-sd &
./run_setup.sh rs256-db &
wait

# Ensure the output directories exist
cd ../../creds
for d in test-vectors/rs256 test-vectors/rs256-sd test-vectors/rs256-db test-vectors/mdl1; do
  if [ ! -d "$d" ]; then
    echo "❌ Error: Missing directory creds/$d" >&2
    exit 1
  fi
done

if [ "$do_trim" = true ]; then
  echo "Cleaning up intermediate artifacts..."
  rm -rf ../circuit_setup/generated_files/!(README.md)
fi

# green "Setup completed in $SECONDS seconds" # 620 317
# read -n 1 -s -r -p "Press any key to continue..."
# SECONDS=0

# cd creds
cargo build $RELEASE_FLAG --features print-trace --bin crescent
mkdir -p bin
cp -f ./target/release/crescent.exe bin/crescent.exe

crescent=./bin/crescent.exe

if [ "$do_trim" = true ]; then
  echo "Cleaning up build artifacts..."
  cargo clean
fi

declare -A LABEL_COLORS=(
  [rs256]=$'\033[0;35m'
  [rs256-sd]=$'\033[0;36m'
  [rs256-db]=$'\033[1;33m'
  [mdl1]=$'\033[1;34m'
)

RESET=$'\033[0m'

for name in "${!LABEL_COLORS[@]}"; do
  color="${LABEL_COLORS[$name]}"
  {
    $crescent zksetup --name "$name"
    $crescent prove   --name "$name"
    $crescent show    --name "$name"
    $crescent verify  --name "$name"
  } 2>&1 | sed "s/^/\\${color}[${name}]\\${RESET} /" &
done

wait


#
# Sample setup
#
cd ../sample
# Node must be available for the .js scripts to be executed
./setup-sample.sh

green "Sample completed in $SECONDS seconds" # 773 620
