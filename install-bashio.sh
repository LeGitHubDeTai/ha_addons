#!/bin/bash
# install-bashio.sh - Installation script for bashio library
# Usage: ./install-bashio.sh
# This script installs the bashio library for Home Assistant add-ons

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running in container
if [ ! -f /.dockerenv ]; then
    print_warning "Not running in a Docker container, but continuing anyway..."
fi

# Check if bashio is already installed
if command -v bashio &> /dev/null; then
    print_status "bashio is already installed"
    bashio --version
    exit 0
fi

# Install required packages
print_status "Installing required packages..."
apt-get update
apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    jq

# Download and install bashio
print_status "Downloading and installing bashio..."

# Get the latest bashio version or use a specific one
BASHIO_VERSION="0.13.0"
BASHIO_URL="https://github.com/hassio-addons/bashio/releases/download/${BASHIO_VERSION}/bashio-${BASHIO_VERSION}-$(dpkg --print-architecture).tar.gz"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Download bashio
print_status "Downloading bashio from $BASHIO_URL"
curl -fsSL "$BASHIO_URL" -o "$TEMP_DIR/bashio.tar.gz"

# Extract and install
print_status "Extracting and installing bashio..."
cd "$TEMP_DIR"
tar -xzf bashio.tar.gz

# Install bashio
if [ -f "bashio" ]; then
    chmod +x bashio
    mv bashio /usr/local/bin/bashio
    print_status "bashio installed successfully"
else
    print_error "bashio binary not found in archive"
    exit 1
fi

# Verify installation
if command -v bashio &> /dev/null; then
    print_status "bashio installation verified"
    bashio --version
else
    print_error "bashio installation failed"
    exit 1
fi

# Clean up
print_status "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

print_status "bashio installation completed successfully!"
