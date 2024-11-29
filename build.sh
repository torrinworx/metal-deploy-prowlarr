#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Define user and directory variables
USER="metal_deploy_prowlarr"
HOME_DIR="/home/$USER"
REPO_DIR="$HOME_DIR/repo"
BUILD_DIR="$REPO_DIR/build"
ARCHIVE_NAME="Prowlarr.tar.gz"

# Clean up previous builds and leftover files
rm -rf "$BUILD_DIR"
rm -f "$REPO_DIR/$ARCHIVE_NAME"

# Ensure necessary packages are installed
apt update && apt install -y curl sqlite3

# Determine architecture
arch=$(dpkg --print-architecture)
case $arch in
	amd64) arch="x64" ;;
	arm|armf|armh) arch="arm" ;;
	*) echo "Unsupported architecture: $arch" && exit 1 ;;
esac

# Download Prowlarr package
wget --content-disposition "http://prowlarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=$arch" -O "$REPO_DIR/$ARCHIVE_NAME"

# Extract into the build directory
mkdir -p "$BUILD_DIR"
tar -xvzf "$REPO_DIR/$ARCHIVE_NAME" -C "$BUILD_DIR"

# Create data directory
mkdir -p "$BUILD_DIR/prowlarr-data"

# Set ownership and permissions for the entire build directory
chown -R $USER:$USER "$BUILD_DIR"
chmod -R u+rwx "$BUILD_DIR"

# Create run.sh script in the build directory
cat <<'EOF' > "$BUILD_DIR/run.sh"
#!/bin/bash

# Define the base directory where your application is running
BASE_DIR="$(dirname "$0")"

# Convert the relative path to an absolute path
DATA_DIR="$BASE_DIR/prowlarr-data"
DATA_DIR=$(readlink -f "$DATA_DIR")

# Run Prowlarr with an absolute path for the data directory
exec "$BASE_DIR/Prowlarr" -nobrowser -data="$DATA_DIR"
EOF

chmod +x "$BUILD_DIR/run.sh"
rm "$REPO_DIR/$ARCHIVE_NAME"

echo "Build complete. Run './repo/build/run.sh' to start Prowlarr."
