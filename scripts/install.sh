#!/bin/sh
# Installer for justview
# Usage: curl -sSL https://raw.githubusercontent.com/pascalwiemers/justview-downloads/main/scripts/install.sh | sh
set -eu

REPO="pascalwiemers/justview-downloads"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Linux)
        ASSET="justview-linux-x86_64.tar.gz"
        ;;
    Darwin)
        ASSET="justview-macos-universal.tar.gz"
        ;;
    *)
        echo "Error: unsupported OS '$OS'. Use install.ps1 for Windows." >&2
        exit 1
        ;;
esac

case "$ARCH" in
    x86_64|amd64|aarch64|arm64) ;;
    *)
        echo "Error: unsupported architecture '$ARCH'." >&2
        exit 1
        ;;
esac

echo "Fetching latest release..."
TAG=$(curl -sSf "https://api.github.com/repos/$REPO/releases/latest" | \
    grep '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')

if [ -z "$TAG" ]; then
    echo "Error: could not determine latest release." >&2
    exit 1
fi

URL="https://github.com/$REPO/releases/download/$TAG/$ASSET"
echo "Downloading justview $TAG for $OS ($ARCH)..."

mkdir -p "$INSTALL_DIR"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

curl -sSfL "$URL" -o "$TMPDIR/justview.tar.gz"
tar xzf "$TMPDIR/justview.tar.gz" -C "$TMPDIR"
mv "$TMPDIR/justview" "$INSTALL_DIR/justview"
chmod +x "$INSTALL_DIR/justview"

if [ "$OS" = "Darwin" ]; then
    xattr -cr "$INSTALL_DIR/justview" 2>/dev/null || true
fi

if "$INSTALL_DIR/justview" --version >/dev/null 2>&1; then
    VERSION=$("$INSTALL_DIR/justview" --version)
    echo "Installed: $VERSION -> $INSTALL_DIR/justview"
else
    echo "Warning: installed binary at $INSTALL_DIR/justview but could not verify." >&2
fi

case ":$PATH:" in
    *":$INSTALL_DIR:"*) ;;
    *)
        echo ""
        echo "Add $INSTALL_DIR to your PATH:"
        echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
        echo ""
        echo "Add that line to your ~/.bashrc or ~/.zshrc to make it permanent."
        ;;
esac
