#!/usr/bin/env bash

# github: https://github.com/ssokka/ubuntu/blob/master/.oci/oci-get-wavve-ip.sh

log() {
    echo "`date "+%Y-%m-%d %H:%M:%S"`|$script_name|$1"
}

cyn() {
    while true; do
        read -er -n 1 -p "! Continue? [y/n] " yn
        case $yn in
            [Yy]*) break;;
            [Nn]*) log "*** End ***"; exit 1;;
            *) echo -en "\033[1A\033[2K";;
        esac
    done
}

log "*** Start ***"

if ! lsb_release -i | grep -iq ubuntu; then
    log "ERROR: not ubuntu"
    exit 1
fi

grep -iq microsoft /proc/version && wsl=true

log "install docker"
if [ -z `which docker` ]; then
    if ! $wsl; then
        # curl -fsSL https://get.docker.com | sudo sh
        sudo apt-get purge --auto-remove -yqq \
            docker \
            docker.io
        sudo apt-get update -yqq
        sudo apt-get install -yqq --no-install-recommends \
            apt-transport-https \
            ca-certificates \
            gnupg \
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository \
            "deb [arch=`dpkg --print-architecture`] https://download.docker.com/linux/ubuntu \
            `lsb_release -cs` \
            stable"
        sudo apt-get update -yqq
        sudo apt-get install -yqq --no-install-recommends \
            docker-ce
    else
        echo "! Docker Desktop on Windows"
        echo "! 01. Install > https://docs.docker.com/desktop/windows/install"
        echo "! 02. Setting > https://docs.docker.com/desktop/windows/#settings"
        cyn
    fi
fi
sudo usermod -aG docker $USER
docker --version

work_dir="$HOME/.oci"
mkdir -p "$work_dir"
if [[ ! -f "$work_dir/config" ]] || [[ -z `find "$work_dir/" -type f -name "*.pem"` ]]; then
    log "Check OCI Private API Key"
    echo "! 01. Check > https://github.com/ssokka/ubuntu/tree/master/.oci#oci-private-api-key"
    cyn
fi

docker_file="$work_dir/dockerfile"
docker_image="oci"
docker_name="oci-get-wavve-ip"
docker_hostname="`hostname`-oci-docker"
docker_hostname="${docker_hostname^^}"

if [[ -z `docker images -q "$docker_image"` ]]; then
    log "Build OCI Docker Image"
    cat > "$docker_file" << EOF
FROM ubuntu
RUN sed -i -r 's/archive.ubuntu.com|security.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list && \\
    apt update -yqq && \\
    apt install -yqq --no-install-recommends python3 python3-pip && \\
    pip install --no-cache-dir --upgrade pip && \\
    pip install --no-cache-dir oci discord_webhook
EOF
    docker build -t "$docker_image" "$work_dir"
fi

if [[ -z `docker ps -a --format {{.Names}} | grep -w "$docker_name"` ]]; then
    log "Run OCI Docker Container"
    docker run -dit --name "$docker_name" \
    --hostname "$docker_hostname" \
    -v ~/.oci:/root/.oci:ro \
    -v /etc/localtime:/etc/localtime:ro \
    -v /etc/resolv.conf:/etc/resolv.conf:ro \
    --log-opt max-size=10m \
    "$docker_image"
else
    if [[ -z `docker container inspect -f '{{.State.Running}}' "$docker_name" | grep -w "true"` ]]; then
        log "Start OCI Docker Container"
        docker start "$docker_name" &> /dev/null
    fi
fi

log "Download & Run Python Script"
py="oci-get-wavve-ip.py"
curl -fsSL https://raw.githubusercontent.com/ssokka/ubuntu/master/.oci/$py > "$work_dir/$py"
if [[ ! -f "$work_dir/$py" ]]; then
    log "ERROR: not exist $work_dir/$py"
    exit 1
fi
args=$@
docker exec -d "$docker_name" bash -c "python3 ~/.oci/$py $args > /dev/console"

log "View OCI Docker Logs Command"
echo "docker logs "$docker_name" -f --tail 10"

log "*** End ***"
