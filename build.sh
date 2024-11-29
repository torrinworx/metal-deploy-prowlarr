#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Define the user and home directory
USER="metal_deploy_prowlarr"
HOME_DIR="/home/$USER"
BUILD_DIR="$HOME_DIR/build"

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

# Download and extract the Prowlarr package, assuming consistent naming after download
wget --content-disposition \
	"http://prowlarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=$arch" \
	-O "$ARCHIVE_NAME"

# Create or clean the build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Extract into the build directory
tar -xvzf "$ARCHIVE_NAME" -C "$BUILD_DIR"

# Ensure Prowlarr directory is named consistently
mv "$BUILD_DIR/Prowlarr"* "$BUILD_DIR/Prowlarr"

# Create the data directory
mkdir -p "$BUILD_DIR/prowlarr-data"

# Ensure correct permissions
chown -R $USER:$USER "$BUILD_DIR"
chmod -R u+rwx "$BUILD_DIR"

# Re-establish run.sh in the build directory
cat <<'EOF' > "$BUILD_DIR/run.sh"
#!/bin/bash

# Define the base directory where your application is running
BASE_DIR="$(dirname "$0")"

# Absolute path setup
DATA_DIR="$BASE_DIR/prowlarr-data"
DATA_DIR=$(readlink -f "$DATA_DIR")

# Correct execution command with paths
exec "$BASE_DIR/Prowlarr/Prowlarr" -nobrowser -data="$DATA_DIR"
EOF

chmod +x "$BUILD_DIR/run.sh"
rm "$ARCHIVE_NAME"

echo "Build complete. Run './build/run.sh' to start Prowlarr."
