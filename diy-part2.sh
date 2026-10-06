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
