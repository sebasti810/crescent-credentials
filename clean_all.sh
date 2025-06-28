#!/usr/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.
#

# Enable glob pattern matching
shopt -s extglob

# clean Rust targets
for d in circuit_setup/mdl-tools creds ecdsa-pop sample; do
  (cd $d && cargo clean && rm -f Cargo.lock)
done


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
