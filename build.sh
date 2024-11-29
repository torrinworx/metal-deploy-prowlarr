#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Define the user and home directory
USER="metal_deploy_prowlarr"
HOME_DIR="/home/$USER"

# Ensure necessary packages are installed
apt update
apt install -y curl sqlite3

# Determine architecture
arch=$(dpkg --print-architecture)
case $arch in
    amd64) arch="x64" ;;
    arm|armf|armh) arch="arm" ;;
    *) echo "Unsupported architecture: $arch" && exit 1 ;;
esac

# Define the filename for the downloaded archive
ARCHIVE_NAME="$HOME_DIR/Prowlarr.tar.gz"

# Download the Prowlarr package
wget --content-disposition \
    "http://prowlarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=$arch" \
    -O "$ARCHIVE_NAME"

# Ensure build directory exists, clean up previous builds
BUILD_DIR="$HOME_DIR/build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Extract the package into the build directory
tar -xvzf "$ARCHIVE_NAME" -C "$BUILD_DIR"

# Ensure the specific directory exists after extraction
mv "$BUILD_DIR/Prowlarr/" "$BUILD_DIR/Prowlarr"

# Create the data directory
mkdir -p "$BUILD_DIR/prowlarr-data"

# Set ownership and permissions for the entire build directory
chown -R $USER:$USER "$BUILD_DIR"
chmod -R u+rwx "$BUILD_DIR"

# Create the run.sh script with absolute paths
cat <<'EOF' > "$BUILD_DIR/run.sh"
#!/bin/bash

# Define the base directory where your application is running
BASE_DIR="$(dirname "$0")"

# Convert the relative path to absolute path
DATA_DIR="$BASE_DIR/prowlarr-data"

# Ensure that DATA_DIR is an absolute path
DATA_DIR=$(readlink -f "$DATA_DIR")

# Run Prowlarr with an absolute path for the data directory
exec "$BASE_DIR/Prowlarr/Prowlarr" -nobrowser -data="$DATA_DIR"
EOF

chmod +x "$BUILD_DIR/run.sh"
rm "$ARCHIVE_NAME"

echo "Build complete. Run './build/run.sh' to start Prowlarr."
