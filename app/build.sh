#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")"
mkdir -p out
javac -d out src/BarqLite.java
jar cfm ../ansible/files/barq-lite.jar manifest.mf -C out .
echo "Built ansible/files/barq-lite.jar"

