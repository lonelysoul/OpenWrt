#!/bin/bash

# sed -i 's/--set=llvm\.download-ci-llvm=false/--set=llvm.download-ci-llvm=true/' feeds/packages/lang/rust/Makefile
# git clone https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
# git clone https://github.com/JohnsonRan/luci-app-kixdns.git package/kixdns
git clone https://github.com/QiuSimons/luci-app-dae.git package/dae

# ==================================================================
# 1. 下载最新 GeoIP / GeoSite 打入固件（解决刷机/开机无规则的死锁问题）
# ==================================================================
echo "--> 预置最新的 GeoIP / GeoSite 数据库到固件..."
mkdir -p files/usr/share/v2ray
rm -f files/usr/share/v2ray/geoip.dat files/usr/share/v2ray/geosite.dat

wget -q --no-check-certificate -O files/usr/share/v2ray/geoip.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
wget -q --no-check-certificate -O files/usr/share/v2ray/geosite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat

# ==================================================================
# 2. 将 update-v2ray-rules 更新脚本写入 files/usr/bin/
# ==================================================================
echo "--> 写入 /usr/bin/update-v2ray-rules 脚本..."
mkdir -p files/usr/bin

cat << 'EOF' > files/usr/bin/update-v2ray-rules
#!/bin/sh

TARGET_DIR="/usr/share/v2ray"
TMP_DIR="/tmp/v2ray-rules"

BASE_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download"

GEOIP="geoip.dat"
GEOSITE="geosite.dat"

log() {
    echo "[v2ray-rules] $*"
}

download() {
    URL="$1"
    OUTPUT="$2"

    if command -v uclient-fetch >/dev/null 2>&1; then
        uclient-fetch \
            -q \
            -O "$OUTPUT" \
            "$URL"
    elif command -v wget >/dev/null 2>&1; then
        wget \
            -q \
            -O "$OUTPUT" \
            "$URL"
    else
        log "ERROR: uclient-fetch/wget not found"
        return 1
    fi
}

verify_sha256() {
    FILE="$1"
    SUM="$2"

    if command -v sha256sum >/dev/null 2>&1; then
        EXPECTED="$(awk '{print $1}' "$SUM")"
        ACTUAL="$(sha256sum "$FILE" | awk '{print $1}')"

        if [ "$EXPECTED" != "$ACTUAL" ]; then
            log "ERROR: SHA256 mismatch: $FILE"
            log "Expected: $EXPECTED"
            log "Actual:   $ACTUAL"
            return 1
        fi

        log "SHA256 OK: $FILE"
        return 0
    fi

    log "WARNING: sha256sum not found, skip verification"
    return 0
}

mkdir -p "$TARGET_DIR"

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

log "Starting update..."

#
# geoip.dat
#

log "Downloading geoip.dat..."

download \
    "$BASE_URL/$GEOIP" \
    "$TMP_DIR/$GEOIP" || exit 1

download \
    "$BASE_URL/$GEOIP.sha256sum" \
    "$TMP_DIR/$GEOIP.sha256sum" || exit 1

[ -s "$TMP_DIR/$GEOIP" ] || {
    log "ERROR: geoip.dat is empty"
    exit 1
}

verify_sha256 \
    "$TMP_DIR/$GEOIP" \
    "$TMP_DIR/$GEOIP.sha256sum" || exit 1


#
# geosite.dat
#

log "Downloading geosite.dat..."

download \
    "$BASE_URL/$GEOSITE" \
    "$TMP_DIR/$GEOSITE" || exit 1

download \
    "$BASE_URL/$GEOSITE.sha256sum" \
    "$TMP_DIR/$GEOSITE.sha256sum" || exit 1

[ -s "$TMP_DIR/$GEOSITE" ] || {
    log "ERROR: geosite.dat is empty"
    exit 1
}

verify_sha256 \
    "$TMP_DIR/$GEOSITE" \
    "$TMP_DIR/$GEOSITE.sha256sum" || exit 1


#
# Replace
#

log "Installing new rule files..."

mv -f "$TMP_DIR/$GEOIP" "$TARGET_DIR/$GEOIP"
mv -f "$TMP_DIR/$GEOSITE" "$TARGET_DIR/$GEOSITE"

# 如果 dae 正在运行，自动重载规则
if pgrep dae >/dev/null 2>&1; then
    log "Reloading dae..."
    /etc/init.d/dae reload 2>/dev/null || true
fi

rm -rf "$TMP_DIR"

log "Update completed."

ls -lh \
    "$TARGET_DIR/$GEOIP" \
    "$TARGET_DIR/$GEOSITE"
EOF

chmod +x files/usr/bin/update-v2ray-rules

# ==================================================================
# 3. 注入 UCI 初始化脚本（首次开机自动添加 Cron 定时任务）
# ==================================================================
echo "--> 配置首次开机定时任务 (Cron)..."
mkdir -p files/etc/uci-defaults

cat << 'EOF' > files/etc/uci-defaults/99-v2ray-rules-cron
#!/bin/sh

CRON_CMD="0 3 * * 0 /usr/bin/update-v2ray-rules >/dev/null 2>&1"

# 避免重复添加
if ! grep -q "/usr/bin/update-v2ray-rules" /etc/crontabs/root 2>/dev/null; then
    echo "$CRON_CMD" >> /etc/crontabs/root
    /etc/init.d/cron restart 2>/dev/null || true
fi

exit 0
EOF

chmod +x files/etc/uci-defaults/99-v2ray-rules-cron
