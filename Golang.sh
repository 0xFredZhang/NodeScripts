set -e
set -x

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

echo -e "\n# 设置Golang版本" >> /root/.bashrc
echo "gvm use go1.20.1" >> /root/.bashrc
echo "设置Golang版本完毕"