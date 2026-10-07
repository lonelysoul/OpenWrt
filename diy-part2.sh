#!/bin/bash

# sed -i 's/--set=llvm\.download-ci-llvm=false/--set=llvm.download-ci-llvm=true/' feeds/packages/lang/rust/Makefile
# git clone https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
# git clone https://github.com/JohnsonRan/luci-app-kixdns.git package/kixdns
rm -rf feeds/packages/net/v2ray-geodata
git clone https://github.com/QiuSimons/luci-app-dae.git package/dae
git clone https://github.com/lonelysoul/v2ray-geodata package/v2ray-geodata

cat >> target/linux/x86/config-6.18 <<'EOF'
CONFIG_NETKIT=y
# CONFIG_X86_NATIVE_CPU is not set
# CONFIG_X86_SGX is not set
EOF

echo

echo "============================================================"

echo " 更新 luci-app-dae"

echo "============================================================"

DAE_DIR="package/dae"

DAE_MAKEFILE="$DAE_DIR/dae/Makefile"

if [ ! -d "$DAE_DIR/.git" ]; then

    echo "❌ 未找到已克隆的 luci-app-dae：$DAE_DIR"

    exit 1

fi

echo "--> 检测到 package/dae，正在更新..."

cd "$DAE_DIR"

# 丢弃之前可能留下的本地修改

git reset --hard HEAD

git clean -fd

# 获取远程最新提交

git fetch origin

# 强制同步到远程默认分支

git reset --hard origin/HEAD

cd ../..

echo "--> luci-app-dae 更新完成"

echo

echo "============================================================"

echo " 设置 dae 为 AMD64 v3 / AVX2 编译"

echo "============================================================"

if [ ! -f "$DAE_MAKEFILE" ]; then

    echo "❌ 未找到 dae Makefile：$DAE_MAKEFILE"

    exit 1

fi

# 删除已有的 GO_AMD64 设置，避免重复

sed -i '/^GO_AMD64[[:space:]]*:?=/d' "$DAE_MAKEFILE"

# 在 GO_PKG_BUILD_VARS 前加入 GO_AMD64=v3

if grep -q '^GO_PKG_BUILD_VARS+=' "$DAE_MAKEFILE"; then

    sed -i '/^GO_PKG_BUILD_VARS+=/i GO_AMD64:=v3' "$DAE_MAKEFILE"

else

    echo "❌ 未找到 GO_PKG_BUILD_VARS+=，无法设置 GO_AMD64"

    exit 1

fi

echo "--> 已设置 GO_AMD64:=v3"

echo

echo "--> 当前 dae Go AMD64 配置："

grep -n -E '^GO_AMD64[[:space:]]*:?=' "$DAE_MAKEFILE"