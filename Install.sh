#!/bin/bash

if [ "$(id -u)" != "0" ]; then
  echo "此脚本需要以root用户权限运行。"
  echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
  exit 1
fi

function install_lib() {
  apt update && apt upgrade -y
  apt install -y bison gcc make
  apt install -y curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev lz4 snapd
  apt install -y pkg-config curl build-essential libssl-dev libclang-dev ufw docker-compose-plugin -y

  timedatectl set-timezone UTC
}

function install_golang() {
  if ! command -v go &>/dev/null; then
    echo "未检测到 Golang，正在安装..."

    bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
    source /root/.gvm/scripts/gvm

    gvm install go1.4 -B
    gvm use go1.4
    export GOROOT_BOOTSTRAP=$GOROOT

    gvm install go1.18
    gvm use go1.18
    export GOROOT_BOOTSTRAP=$GOROOT

    gvm install go1.20.1
    gvm use go1.20.1
    export GOROOT_BOOTSTRAP=$GOROOT

    gvm install go1.22.2
    gvm use go1.22.2

    echo -e "\n# 设置Golang版本" >>/root/.bashrc
    echo "gvm use go1.22.2" >>/root/.bashrc
    echo "Golang 安装成功"
  else
    echo "Golang 已安装"
  fi
}

function install_node() {
  if command -v node >/dev/null 2>&1; then
    echo "Node.js 已安装"
  else
    echo "Node.js 未安装，正在安装..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
    echo "Node 安装成功"
  fi

  if command -v npm >/dev/null 2>&1; then
    echo "npm 已安装"
  else
    echo "npm 未安装，正在安装..."
    apt install -y npm
    echo "npm 安装成功"
  fi
}

function install_pm2() {
  if command -v pm2 >/dev/null 2>&1; then
    echo "PM2 已安装"
  else
    echo "PM2 未安装，正在安装..."
    npm install -g pm2@latest
    echo "PM2 安装成功"
  fi
}

function install_docker() {
  if ! command -v docker &>/dev/null; then
    echo "未检测到 Docker，正在安装..."
    apt install ca-certificates curl gnupg lsb-release

    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null

    chmod a+r /etc/apt/keyrings/docker.gpg
    apt update

    apt install docker-ce docker-ce-cli containerd.io docker-compose docker-compose-plugin -y

    echo "Docker 安装成功"
  else
    echo "Docker 已安装。"
  fi
}

function main() {
  echo "基础软件安装..."
  install_lib
  install_golang
  install_node
  install_pm2
  install_docker
  echo "[Golang,Node,npm,PM2,Docker]全部安装成功🏅"
  echo "Date $(date)"
  go version
  echo "Node version $(node -v)"
  echo "npm version $(npm -v)"
  echo "PM2 version $(pm2 -v)"
  docker -v
  docker-compose -v
}

main
