#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Update and install necessary packages
sudo apt update
sudo apt install -y curl sqlite3

# Determine architecture
arch=$(dpkg --print-architecture)
case $arch in
    amd64) arch="x64" ;;
    arm|armf|armh) arch="arm" ;;
    arm64) arch="arm64" ;;
    *) echo "Unsupported architecture: $arch" && exit 1 ;;
esac

# Download and uncompress binaries
wget --content-disposition "http://prowlarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=$arch"
tar -xvzf Prowlarr*.linux*.tar.gz

# Prepare directories
mkdir -p ./build/Prowlarr
mv Prowlarr/* ./build/Prowlarr/
mkdir -p ./build/prowlarr-data

# Set ownership and permissions for the entire build directory
chown -R $(whoami):$(whoami) ./build
chmod -R u+rwx ./build

# Create the run.sh script with absolute paths
cat <<'EOF' > ./build/run.sh
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

chmod +x ./build/run.sh
rm Prowlarr*.linux*.tar.gz

echo "Build complete. Run './build/run.sh' to start Prowlarr."
