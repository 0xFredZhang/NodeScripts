#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。/This script needs to be run with root user privileges."
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。/Please try to switch to root user with 'sudo -i' command, then run this script again."
    exit 1
fi

# 导入Socks5代理
read -p "请输入HTTP代理地址 (格式为 host:port)，如不需要代理请留空: /Please enter the HTTP proxy address (format host:port), leave blank if no proxy is needed: " proxy
if [ ! -z "$proxy" ]; then
    export http_proxy=http://$proxy
    export https_proxy=http://$proxy
    echo "已设置HTTP代理为: $proxy /HTTP proxy is set to: $proxy"
else
    echo "未设置代理 /No proxy set"
fi

# 节点安装功能
function install_node() {
    sudo apt update
    sudo apt install -y git python3-venv bison screen binutils gcc make bsdmainutils python3-pip

	# 安装numpy
    sudo pip install numpy==1.24.4

    # 安装GO
    sudo rm -rf /usr/local/go
    wget https://go.dev/dl/go1.22.1.linux-amd64.tar.gz -P /tmp/
    sudo tar -C /usr/local -xzf /tmp/go1.22.1.linux-amd64.tar.gz
    echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bashrc
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    go version

    # 克隆仓库
    sudo rm -rf $HOME/nimble
    mkdir -p $HOME/nimble && cd $HOME/nimble
    git clone https://github.com/nimble-technology/wallet-public.git
    cd wallet-public
    make install
    cd $HOME/nimble
    git clone https://github.com/nimble-technology/nimble-miner-public.git
    cd nimble-miner-public
    make install
    source $HOME/nimble/nimble-miner-public/nimenv_localminers/bin/activate
    # 显卡信息
    lspci | grep VGA
	echo "完成部署"
}

# 创建钱包
function create_wallet(){

    # 创建钱包
    echo "至少创建两个钱包，一个作为主钱包，一个作为挖矿钱包。"
    read -p "请输入钱包数量:" wallet_count
    for i in $(seq 1 $wallet_count); do
        wallet_name="wallet$i"
        if ! nimble-networkd keys add $wallet_name; then
		    nimble-networkd keys add $wallet_name --keyring-backend test
		fi
        echo "钱包 $wallet_name 创建成功"
    done

}

# 开始挖矿
function start_mining(){

    # 启动挖矿
    read -p "挖矿钱包地址:" wallet_addr
    export wallet_addr
    cd $HOME/nimble/nimble-miner-public
    source $HOME/nimble/nimble-miner-public/nimenv_localminers/bin/activate
    screen -dmS nimble bash -c "make run addr=$wallet_addr"
    echo "ctrl + a + d 退出"
	sleep 2
	screen -r nimble
}

# 查看日志
function view_logs(){
	clear
	echo "5秒后进入screen，查看完请ctrl + a + d 退出"
	sleep 5
	screen -r nimble
}

# 主菜单
function main_menu() {
	while true; do
	    clear
	    echo "===================Nimble一键部署脚本==================="
		echo "BreadDog出品，电报：https://t.me/breaddog"
		echo "最低配置：8C16G256G+RTX2080，推荐配置：16C32G256G+RTX3090"
	    echo "请选择要执行的操作:"
	    echo "1. 部署节点"
	    echo "2. 创建钱包"
	    echo "3. 开始挖矿"
	    echo "4. 查看日志"
	    echo "0. 退出脚本exit"
	    read -p "请输入选项: " OPTION

	    case $OPTION in
	    1) install_node ;;
	    2) create_wallet ;;
	    3) start_mining ;;
	    4) view_logs ;;
	    0) echo "退出脚本。"; exit 0 ;;
	    *) echo "无效选项，请重新输入。"; sleep 3 ;;
	    esac
	    echo "按任意键返回主菜单..."
        read -n 1
    done
}

main_menu