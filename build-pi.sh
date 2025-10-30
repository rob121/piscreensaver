#!/bin/bash

# Build script for Raspberry Pi (Linux ARM)
# Usage: ./build-pi.sh [arm|arm64]

set -e

# Default to arm64 (for Raspberry Pi 3+ and 4)
ARCH="${1:-arm64}"

# Validate architecture
if [ "$ARCH" != "arm" ] && [ "$ARCH" != "arm64" ]; then
    echo "Error: Architecture must be 'arm' or 'arm64'"
    echo "Usage: $0 [arm|arm64]"
    exit 1
fi

# Set Go environment variables for cross-compilation
export GOOS=linux
export GOARCH="$ARCH"

# Output binary name
BINARY_NAME="piscreensaver"

# If arm (32-bit), may need to specify ARM version
if [ "$ARCH" = "arm" ]; then
    export GOARM=7  # ARMv7 (for Raspberry Pi 2+)
    BINARY_NAME="piscreensaver-arm"
else
    BINARY_NAME="piscreensaver-arm64"
fi

echo "Building for Linux $ARCH..."
echo "GOOS=$GOOS GOARCH=$GOARCH"

# Build the binary
go build -o "$BINARY_NAME" ./main.go

if [ $? -eq 0 ]; then
    echo "✓ Build successful!"
    echo "  Binary: $BINARY_NAME"
    echo "  Size: $(du -h "$BINARY_NAME" | cut -f1)"
    echo ""
    echo "To transfer to Raspberry Pi:"
    echo "  scp $BINARY_NAME pi@your-pi-ip:/path/to/destination/"
else
    echo "✗ Build failed"
    exit 1
fi

