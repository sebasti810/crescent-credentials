#!/usr/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.
#

# Enable glob pattern matching
shopt -s extglob

# clean Rust targets
cargo clean

# remove generated files
rm -rf circuit_setup/inputs/*/!(*.json)
rm -rf circuit_setup/generated_files/!(README.md)
rm -rf creds/test-vectors/!(README.md)

# clean wasm
rm -rf creds/pkg

# clean sample
cd sample && rm -rf client_helper/data verifier/data issuer/.well-known issuer/keys
cd client && npm run clean
cd ../..
