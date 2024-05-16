#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
  echo "此脚本需要以root用户权限运行。"
  echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
  exit 1
fi

# 节点安装功能
function install_node() {
  # 设置变量
  read -r -p "请输入你想设置的节点名称: " NODE_MONIKER
  export NODE_MONIKER=$NODE_MONIKER

  # 更新和安装必要的软件
  apt update && sudo apt upgrade -y
  apt install -y curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev lz4 snapd

  # Go版本
  source /root/.gvm/scripts/gvm
  gvm use go1.22.2

  # 安装所有二进制文件
  git clone https://github.com/artela-network/artela
  cd artela || exit
  git checkout v0.4.7-rc7
  make install

  # 配置artelad
  artelad config chain-id artela_11822-1
  artelad init "$NODE_MONIKER" --chain-id artela_11822-1
  artelad config node tcp://localhost:3457

  # 获取初始文件和地址簿
  curl -L https://snapshots-testnet.nodejumper.io/artela-testnet/genesis.json >$HOME/.artelad/config/genesis.json
  curl -L https://snapshots-testnet.nodejumper.io/artela-testnet/addrbook.json >$HOME/.artelad/config/addrbook.json

  # 配置节点
  PEERS="096d8b3a2fe79791ef307935e0b72afcf505b149@84.247.140.122:24656,a01a5d0015e685655b1334041d907ce2db51c02f@173.249.16.25:45656,8542e4e88e01f9c95db2cd762460eecad2d66583@155.133.26.10:26656,dd5d35fb496afe468dd35213270b02b3a415f655@15.235.144.20:30656,8510929e6ba058e84019b1a16edba66e880744e1@217.76.50.155:656,f16f036a283c5d2d77d7dc564f5a4dc6cf89393b@91.190.156.180:42656,6554c18f24455cf1b60eebcc8b311a693371881a@164.68.114.21:45656,301d46637a338c2855ede5d2a587ad1f366f3813@95.217.200.98:18656"
  sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.artelad/config/config.toml

  # 配置端口
  node_address="tcp://localhost:3457"
  sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:3458\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:3457\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:3460\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:3456\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":3466\"%" $HOME/.artelad/config/config.toml
  sed -i -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:3417\"%; s%^address = \":8080\"%address = \":3480\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:3490\"%; s%^address = \"localhost:9091\"%address = \"0.0.0.0:3491\"%; s%:8545%:3445%; s%:8546%:3446%; s%:6065%:3465%" $HOME/.artelad/config/app.toml
  echo "export Artela_RPC_PORT=$node_address" >>$HOME/.bashrc
  source $HOME/.bashrc

  pm2 start artelad -- start && pm2 save && pm2 startup

  # 下载快照
  artelad tendermint unsafe-reset-all --home $HOME/.artelad --keep-addr-book
  curl https://snapshots-testnet.nodejumper.io/artela-testnet/artela-testnet_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.artelad
  mv $HOME/.artelad/priv_validator_state.json.backup $HOME/.artelad/data/priv_validator_state.json

  # 使用 PM2 启动节点进程

  pm2 restart artelad

  echo "====================== 安装完成,请退出脚本后执行 source $HOME/.bash_profile 以加载环境变量 ==========================="
}

# 查看Artela 服务状态
function check_service_status() {
  pm2 list
}

# Artela 节点日志查询
function view_logs() {
  pm2 logs artelad
}

# 卸载节点功能
function uninstall_node() {
  echo "你确定要卸载Artela 节点程序吗？这将会删除所有相关的数据。[Y/N]"
  read -r -p "请确认: " response

  case "$response" in
  [yY][eE][sS] | [yY])
    echo "开始卸载节点程序..."
    pm2 stop artelad && pm2 delete artelad
    rm -rf $HOME/.artelad $HOME/artela $(which artelad)
    echo "节点程序卸载完成。"
    ;;
  *)
    echo "取消卸载操作。"
    ;;
  esac
}

# 创建钱包
function add_wallet() {
  source /root/.gvm/scripts/gvm
  gvm use go1.22.2
  artelad keys add wallet
}

# 导入钱包
function import_wallet() {
  source /root/.gvm/scripts/gvm
  gvm use go1.22.2
  artelad keys add wallet --recover
}

# 查询余额
function check_balances() {
  source /root/.gvm/scripts/gvm
  gvm use go1.22.2
  read -p "请输入钱包地址: " wallet_address
  artelad query bank balances "$wallet_address" --node $Artela_RPC_PORT
}

# 查看节点同步状态
function check_sync_status() {
  source /root/.gvm/scripts/gvm
  gvm use go1.22.2
  artelad status --node $Artela_RPC_PORT | jq .SyncInfo
}

# 创建验证者
function add_validator() {
  source /root/.gvm/scripts/gvm
  gvm use go1.22.2

  read -p "请输入您的钱包名称: " wallet_name
  read -p "请输入您想设置的验证者的名字: " validator_name

  artelad tx staking create-validator --node $Artela_RPC_PORT \
    --amount 1000000uart \
    --from $wallet_name \
    --commission-rate 0.1 \
    --commission-max-rate 0.2 \
    --commission-max-change-rate 0.01 \
    --min-self-delegation 1 \
    --pubkey $(artelad tendermint show-validator) \
    --moniker "$validator_name" \
    --identity "" \
    --details "" \
    --chain-id artela_11822-1 \
    --gas 300000
}

# 给自己地址验证者质押
function delegate_self_validator() {
  source /root/.gvm/scripts/gvm
  gvm use go1.22.2

  read -p "请输入质押代币数量: " math
  read -p "请输入钱包名称: " wallet_name
  artelad tx staking delegate $(artelad keys show $wallet_name --bech val -a) ${math}art --from $wallet_name --chain-id=artela_11822-1 --gas=300000 --node $Artela_RPC_PORT -y
}

# 导出验证者key
function export_priv_validator_key() {
  echo "====================请将下方所有内容备份到自己的记事本或者excel表格中记录==========================================="
  cat ~/.artelad/config/priv_validator_key.json
}

# 主菜单
function main_menu() {
  while true; do
    clear
    echo "脚本改编自推特用户大赌哥 @y95277777"
    echo "================================================================"
    echo "请选择要执行的操作:"
    echo "1. 安装节点"
    echo "2. 创建钱包"
    echo "3. 导入钱包"
    echo "4. 查看钱包地址余额"
    echo "5. 查看节点同步状态"
    echo "6. 查看当前服务状态"
    echo "7. 运行日志查询"
    echo "8. 卸载节点"
    echo "9. 设置快捷键"
    echo "10. 创建验证者"
    echo "11. 给自己质押"
    echo "12. 备份验证者私钥"
    read -p "请输入选项（1-11）: " OPTION

    case $OPTION in
    1) install_node ;;
    2) add_wallet ;;
    3) import_wallet ;;
    4) check_balances ;;
    5) check_sync_status ;;
    6) check_service_status ;;
    7) view_logs ;;
    8) uninstall_node ;;
    9) check_and_set_alias ;;
    10) add_validator ;;
    11) delegate_self_validator ;;
    12) export_priv_validator_key ;;
    0)
      echo "退出脚本。"
      exit 0
      ;;
    *)
      echo "无效选项，请重新输入。"
      sleep 1
      ;;
    esac
    echo "按任意键返回主菜单..."
  done

}

# 显示主菜单
main_menu
