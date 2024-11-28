#!/bin/bash

set -e

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

# Move files to the build directory
mkdir -p ./build
mv Prowlarr ./build/

# Create the run.sh script
cat <<'EOF' > ./build/run.sh
#!/bin/bash

# Set the necessary environment variables
source ./.env

# Run Prowlarr
exec /opt/Prowlarr/Prowlarr -nobrowser -data=/var/lib/prowlarr/
EOF

chmod +x ./build/run.sh

# Cleanup
rm Prowlarr*.linux*.tar.gz

echo "Build complete. Run './build/run.sh' to start Prowlarr."
