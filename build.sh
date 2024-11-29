#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Define user and directory variables
USER="metal_deploy_prowlarr"
HOME_DIR="/home/$USER"
BUILD_DIR="$HOME_DIR/build"
ARCHIVE_NAME="$HOME_DIR/Prowlarr.tar.gz"

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
wget --content-disposition \
	"http://prowlarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=$arch" \
	-O "$ARCHIVE_NAME"

# Prepare the build directory
rm -rf "$BUILD_DIR"  # Clean up previous build
mkdir -p "$BUILD_DIR"

# Extract into build directory
tar -xvzf "$ARCHIVE_NAME" -C "$BUILD_DIR"

# Check for extracted directory and move accordingly
if [ -d "$BUILD_DIR/Prowlarr" ]; then
	rm -rf "$BUILD_DIR/Prowlarr/Prowlarr"
else
	mkdir -p "$BUILD_DIR/Prowlarr"
	mv "$BUILD_DIR/"* "$BUILD_DIR/Prowlarr/"
fi

# Create data directory
mkdir -p "$BUILD_DIR/Prowlarr/prowlarr-data"

# Set ownership and permissions
chown -R $USER:$USER "$BUILD_DIR"
chmod -R u+rwx "$BUILD_DIR"

# Create run.sh script
cat <<'EOF' > "$BUILD_DIR/Prowlarr/run.sh"
#!/bin/bash

# Define the base directory where your application is running
BASE_DIR="$(dirname "$0")"

# Convert the relative path to an absolute path
DATA_DIR="$BASE_DIR/prowlarr-data"
DATA_DIR=$(readlink -f "$DATA_DIR")

# Run Prowlarr with an absolute path for the data directory
exec "$BASE_DIR/Prowlarr" -nobrowser -data="$DATA_DIR"
EOF

chmod +x "$BUILD_DIR/Prowlarr/run.sh"
rm "$ARCHIVE_NAME"

echo "Build complete. Run './build/Prowlarr/run.sh' to start Prowlarr."
