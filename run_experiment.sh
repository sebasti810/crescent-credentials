#!/bin/bash
# Crescent timing-attack experiment: honest circuit vs padded (gadget) circuit.
# For each condition it compiles the circuit, runs zksetup, then sweeps the
# hidden "age" claim and records proving time. Results are saved in results/<cond>_<host>.csv

set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
export PATH="$ROOT/circuit_setup/.venv/bin:$HOME/.cargo/bin:$PATH"
BIN="$ROOT/creds/target/release/crescent"
IN="$ROOT/circuit_setup/inputs/rs256"
TV="$ROOT/creds/test-vectors/rs256"
OUT="$ROOT/results"; mkdir -p "$OUT"
HOST="$(hostname -s)"
AGES="0 25 50 75 100"
REPS=5

echo "Building prover (release, print-trace)..."
( cd "$ROOT/creds" && cargo build --bin crescent --release --features print-trace )

run_condition () {
  local cond="$1" cfg="$2"
  echo "CONDITION: $cond  (host $HOST)"
  cp "$cfg" "$IN/config.json"
  rm -f "$IN/token.jwt"                                  # force a real re-sign
  ( cd "$ROOT/circuit_setup/scripts" && ./run_setup.sh rs256 )   # recompile circuit
  ( cd "$ROOT/creds" && cargo run --bin crescent --release --features print-trace zksetup --name rs256 )
  local CSV="$OUT/${cond}_${HOST}.csv"
  echo "age,rep,compute_c_s,groth16_prove_s,wall_total_s" > "$CSV"
  for age in $AGES; do
    sed -i "s/\"age\": [0-9]*/\"age\": $age/" "$IN/claims.json"
    python3 "$ROOT/circuit_setup/scripts/jwt_sign.py" "$IN/claims.json" "$IN/issuer.prv" "$IN/token.jwt" "$IN/device.pub" >/dev/null 2>&1
    cp "$IN/token.jwt" "$TV/token.jwt"
    echo "-> $cond age=$age <-"
    cd "$ROOT/creds"
    for i in $(seq 1 $REPS); do
      t0=$(date +%s.%N)
      out=$("$BIN" prove --name rs256 2>&1)
      t1=$(date +%s.%N)
      cc=$(echo "$out" | grep -m1 'Compute C '     | sed -E 's/\.{3,}/ /' | awk '{print $NF}' | sed 's/s$//')
      gp=$(echo "$out" | grep -m1 'Groth16 prove '  | sed -E 's/\.{3,}/ /' | awk '{print $NF}' | sed 's/s$//')
      wall=$(awk "BEGIN{printf \"%.3f\", $t1-$t0}")
      echo "  rep $i: C=${cc}s  prove=${gp}s  wall=${wall}s"
      echo "$age,$i,$cc,$gp,$wall" >> "$CSV"
    done
  done
  echo "saved -> $CSV"
}

run_condition honest "$IN/config_honest.json"
run_condition padded "$IN/config_padded.json"
echo "DONE. CSVs in $OUT/  (honest_${HOST}.csv, padded_${HOST}.csv)"
