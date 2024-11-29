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

mkdir -p ./build/Prowlarr
mv Prowlarr/* ./build/Prowlarr/
mkdir -p ./build/prowlarr-data

chown -R $(whoami):$(whoami) ./build/prowlarr-data
chmod -R u+rwx ./build/prowlarr-data

cat <<'EOF' > ./build/run.sh
#!/bin/bash

# Run Prowlarr with a local data directory within the user's directory
exec "$(dirname "$0")/Prowlarr/Prowlarr" -nobrowser -data="$(dirname "$0")/prowlarr-data"
EOF

chmod +x ./build/run.sh
rm Prowlarr*.linux*.tar.gz
