#!/usr/bin/env bash

# useage
# curl -fsSL https://raw.githubusercontent.com/ssokka/ubuntu/master/ubuntu-basic-setting.sh | bash

[ $0 == bash ] && script_name="ubuntu-basic-setting.sh" || script_name=$0

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

grep -iq oracle /proc/version && oci=true
grep -iq microsoft /proc/version && wsl=true

log "setting timezone to Asia/Seoul"
! $wsl && sudo timedatectl set-timezone Asia/Seoul
date

log "setting 2G swap"
if [ `swapon -s | wc -l` -eq 0 ]; then
    file=/swapfile
    sudo fallocate -l 2G $file
    sudo chmod 600 $file
    sudo mkswap $file
    sudo swapon $file
    echo "$file swap swap default 0 0" | sudo tee -a /etc/fstab
fi
free -h

log "remove snap"
sudo apt-get purge --auto-remove -yqq snapd
sudo apt-mark hold snap

log "change apt source to mirror.kakao.com"
file="/etc/apt/sources.list"
[ ! -f $file.bak ] && sudo cp $file $file.bak
sudo sed -i -r 's/archive.ubuntu.com|security.ubuntu.com/mirror.kakao.com/g' $file

log "organize packages"
sudo apt-get update -yqq && \
sudo apt-get upgrade -yqq && \
sudo apt-get autoremove -yqq && \
sudo apt-get autoclean -yqq

log "install common packages"
sudo apt-get install -yqq --no-install-recommends \
    bmon \
    sqlite3 \
    unzip

log "change nameserver"
sudo apt-get install -yqq --no-install-recommends \
    resolvconf
file=/etc/resolv.conf
[ ! -f $file.bak ] && sudo cp $file $file.bak
sudo chattr -i $file &>/dev/null
sudo bash -c "cat > $file << EOF
nameserver 168.126.63.1
nameserver 168.126.63.2
nameserver 8.8.8.8
nameserver 8.8.4.4
[network]
generateResolvConf=false
EOF"
sudo chattr +i $file
sudo service resolvconf restart
dig | grep -i server:

log "open all inbound ports"
# sudo apt-get install -yqq --no-install-recommends \
#     iptables-persistent
sudo iptables -F
sudo netfilter-persistent save
sudo netfilter-persistent reload
sudo iptables -L

if ! $wsl; then
    # log "install speedtest"
    # curl -s https://install.speedtest.net/app/cli/install.deb.sh | sudo bash
    # sudo apt install speedtest -y
    
    # log "speedtest before tcp bbr"
    # yes | speedtest
    
    log "tcp bbr"
    file=/etc/sysctl.conf
    [ ! -f $file.bak ] && sudo cp $file $file.bak
    line="net.core.default_qdisc=fq"
    grep -qxF "$line" $file || echo "${line}" | sudo tee -a $file
    line="net.ipv4.tcp_congestion_control=bbr"
    grep -qxF "$line" $file || echo "${line}" | sudo tee -a $file
    sudo sysctl -p
    sudo sysctl -a | grep -E 'bbr|fq'

    # log "speedtest after tcp bbr"
    # yes | speedtest
fi

log "install rclone mod"
curl -fsSL https://raw.githubusercontent.com/wiserain/rclone/mod/install.sh | sudo bash

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

log "install docker-compose"
if [ -z `which docker-compose` ]; then
    if ! $wsl; then
        file=/usr/local/bin/docker-compose
        latest=`curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]*)".*/\1/'`
        sudo curl -L "https://github.com/docker/compose/releases/download/$latest/docker-compose-`uname -s`-`uname -m`" -o $file
        sudo chmod +x $file
    else
        "/mnt/c/program files/Docker/Docker/frontend/Docker Desktop.exe" --name=settings
        echo "! 01. Use Docker Compose V2 > Check > Apply & Restore"
        cyn
    fi
fi
docker-compose --version

log "*** End ***"
