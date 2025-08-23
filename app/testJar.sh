#!/bin/bash
set -e

echo ">>> Checking Java version..."
java -version
javac -version

if [ -f "out/BarqLite.jar" ]; then
  echo ">>> Running JAR..."
  java -jar out/BarqLite.jar
elif [ -f "out/BarqLite.class" ]; then
  echo ">>> Running .class file..."
  java -cp out BarqLite
else
  echo "No JAR or .class file found in out/ directory"
  exit 1
fi

