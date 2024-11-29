#!/bin/bash

set -e

apt update
apt install -y curl sqlite3

arch=$(dpkg --print-architecture)
case $arch in
	amd64) arch="x64" ;;
	arm|armf|armh) arch="arm" ;;
	arm64) arch="arm64" ;;
	*) echo "Unsupported architecture: $arch" && exit 1 ;;
esac

wget --content-disposition "http://prowlarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=$arch" -O ./Prowlarr.tar.gz
tar -xvzf ./Prowlarr.tar.gz -C ./

mkdir -p ./build/
mv ./Prowlarr ./build/Prowlarr/
mkdir -p ~/.prowlarr-data

cat <<'EOF' > ./build/run.sh
#!/bin/bash

DATA_DIR=$(readlink -f "$HOME/.prowlarr-data")
exec "./Prowlarr/Prowlarr" -nobrowser -data="$DATA_DIR"
EOF

chmod +x ./build/run.sh
rm ./Prowlarr.tar.gz

echo "Build complete. Run './build/run.sh' to start Prowlarr."
