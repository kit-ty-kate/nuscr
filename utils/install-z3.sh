#!/bin/bash

set -euo pipefail

case "$(uname)" in
  Darwin)
    Z3_FILENAME=z3-4.8.12-x64-osx-10.15.7
    ;;
  Linux)
    # Assume Debian
    Z3_FILENAME=z3-4.8.12-x64-glibc-2.31
    ;;
  *)
    echo "Don't know which z3 to download"
    exit 1
    ;;
esac
curl -o z3.zip -L https://github.com/Z3Prover/z3/releases/download/z3-4.8.12/${Z3_FILENAME}.zip
unzip z3.zip
rm z3.zip
mv ${Z3_FILENAME} z3
mv z3/bin/* /usr/local/bin
mv z3/include/* /usr/local/include

