#!/bin/bash
# test_code.sh - Compile and run BarqLite source code locally

set -e  # exit on first error

SRC_DIR="src"           # adjust if your sources are in another directory
MAIN_CLASS="BarqLite"   # replace with the full package name if needed
BUILD_DIR="build"

echo ">>> Cleaning old build..."
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

echo ">>> Checking Java version..."
java -version
javac -version

echo ">>> Compiling source code..."
javac -d $BUILD_DIR $(find $SRC_DIR -name "*.java")

echo ">>> Running main class..."
java -cp $BUILD_DIR $MAIN_CLASS

