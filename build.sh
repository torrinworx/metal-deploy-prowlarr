#!/bin/bash

set -e  # Exit script immediately on error

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
	arm64) arch="arm64" ;;
	*) echo "Unsupported architecture: $arch" && exit 1 ;;
esac

# Define the filename for the downloaded archive
ARCHIVE_NAME="Prowlarr.tar.gz"

# Download the Prowlarr package
wget --content-disposition "http://prowlarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=$arch" -O "$HOME_DIR/$ARCHIVE_NAME"

# Extract the package directly to the ./build directory
mkdir -p "$HOME_DIR/build"
tar -xvzf "$HOME_DIR/$ARCHIVE_NAME" -C "$HOME_DIR/build"

# Prepare the data directory
mkdir -p "$HOME_DIR/build/prowlarr-data"

# Set ownership and permissions for the entire build directory
chown -R $USER:$USER "$HOME_DIR/build"
chmod -R u+rwx "$HOME_DIR/build"

# Create the run.sh script with absolute paths
cat <<'EOF' > "$HOME_DIR/build/run.sh"
#!/bin/bash

# Define the base directory where your application is running
BASE_DIR="$(dirname "$0")"

# Convert the relative path to an absolute path
DATA_DIR="$BASE_DIR/prowlarr-data"

# Ensure that DATA_DIR is an absolute path
DATA_DIR=$(readlink -f "$DATA_DIR")

# Run Prowlarr with an absolute path for the data directory
exec "$BASE_DIR/Prowlarr/Prowlarr" -nobrowser -data="$DATA_DIR"
EOF

chmod +x "$HOME_DIR/build/run.sh"
rm "$HOME_DIR/$ARCHIVE_NAME"

echo "Build complete. Run './build/run.sh' to start Prowlarr."
