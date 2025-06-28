#!/usr/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.
#

set -e
set -x


# usage: setup-sample.sh

./client_helper/setup_client_helper.sh &
./issuer/setup_issuer.sh &
./verifier/setup_verifier.sh &
wait

./client/setup_client.sh &
cargo build --release &
wait

mv target/release/crescent-sample-client-helper.exe client_helper/crescent-sample-client-helper.exe
mv target/release/crescent-sample-issuer.exe issuer/crescent-sample-issuer.exe
mv target/release/crescent-sample-verifier.exe verifier/crescent-sample-verifier.exe
rm -rf target

cd client
npm run build:debug

# Create json file with base64 encoded mdoc and device private key
# (until we have an issuer to issue mDLs, we use the ones generated in the Crescent lib)
cat <<EOF > mdl.json
{
  "mdoc": "$(base64 -w 0 "../../circuit_setup/inputs/mdl1/mdl.cbor")",
  "devicePrivateKey": "$(base64 -w 0 "../../circuit_setup/inputs/mdl1/device.prv")"
}
EOF

cd ..
