#!/bin/sh
set -ex

ALLOW_FLAGS="
  -A clippy::needless_range_loop
  -A clippy::same_item_push
  -A clippy::should_implement_trait
  -A clippy::result_large_err
"

# Extra rustc lint relaxations (empty by default)
EXTRA_RUSTFLAGS=""

case "$PWD" in
  */ecdsa-pop|*/ecdsa-pop/*)
    # dead_code is a rustc lint → must go into RUSTFLAGS
    EXTRA_RUSTFLAGS="$EXTRA_RUSTFLAGS -Adead_code"
    ;;
esac

# Deny all warnings globally, but allow dead_code in ecdsa-pop
RUSTFLAGS="$EXTRA_RUSTFLAGS -Dwarnings" cargo clippy --release --tests -- \
  --no-deps \
  $ALLOW_FLAGS
