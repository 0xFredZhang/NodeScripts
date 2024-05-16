#!/bin/bash

# fork https://raw.githubusercontent.com/a3165458/Quilibrium/main/Quili.sh

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
  echo "此脚本需要以root用户权限运行。"
  echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
  exit 1
fi

# 节点安装功能
function install_node() {
  # 向/etc/sysctl.conf文件追加内容
  echo -e "\n# 自定义最大接收和发送缓冲区大小" >>/etc/sysctl.conf
  echo "net.core.rmem_max=600000000" >>/etc/sysctl.conf
  echo "net.core.wmem_max=600000000" >>/etc/sysctl.conf
  echo "配置已添加到/etc/sysctl.conf"

  # 重新加载sysctl配置以应用更改
  sysctl -p

  echo "sysctl配置已重新加载"

  # 更新并升级Ubuntu软件包
  apt update && apt -y upgrade

  # 安装wget、screen和git等组件
  apt install git ufw bison screen binutils gcc make bsdmainutils -y

  # 克隆仓库
  git clone https://github.com/quilibriumnetwork/ceremonyclient

  # 进入ceremonyclient/node目录
  cd ceremonyclient/node || exit

  # 赋予执行权限
  chmod +x poor_mans_cd.sh

  # 切换到go1.20.1
  source /root/.gvm/scripts/gvm
  gvm use go1.20.1

  # 创建一个screen会话并运行命令
  screen -dmS Quilibrium bash -c './poor_mans_cd.sh'
}

# 查看常规版本节点日志
function check_service_status() {
  clear
  echo "3秒后进入screen，查看完请ctrl + a + d 退出"
  sleep 3
  screen -r Quilibrium
}

function get_peer_id() {
  source /root/.gvm/scripts/gvm
  gvm use go1.20.1
  cd ceremonyclient/node || exit
  GOEXPERIMENT=arenas go run ./... -peer-id
}

# 主菜单
function main_menu() {
  while true; do
    clear
    echo "脚本改编自推特用户大赌哥 @y95277777"
    echo "================================================================"
    echo "请选择要执行的操作:"
    echo "1. 安装运行常规节点(Screen)"
    echo "2. 查看常规版本节点日志(Screen)"
    echo "3. 查询PeerId"
    read -p "请输入选项（1-3）: " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_service_status ;;
    3) get_peer_id ;;
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
