#!/bin/bash
#============================================================
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
# Lisence: MIT
# Author: P3TERX
# Blog: https://p3terx.com
#============================================================

# Modify default IP
sed -i 's/192.168.6.1/192.168.233.1/g' package/base-files/files/bin/config_generate

# Limit OpenClash sysupgrade backups to persistent user data. Downloadable
# runtime assets such as the core and GeoIP/GeoSite databases can otherwise
# make the backup too large to restore safely on devices with small flash.

# ============================================================
# 克隆第三方插件
# ============================================================

# --- nikki ---
log "克隆 nikki"
git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-nikki package/nikki
# nikki: 清除默认值，避免与用户配置冲突
log "nikki: 清除默认值 log_level/ui_url/tun_stack"
sed -i "/option 'log_level' 'warning'/d" package/nikki/nikki/files/nikki.conf
sed -i "\#option 'ui_url' 'https://github.com/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip'#d" package/nikki/nikki/files/nikki.conf
sed -i "/option 'tun_stack' 'mixed'/d" package/nikki/nikki/files/nikki.conf

# --- lucky ---
log "克隆 lucky"
git clone --depth=1 https://github.com/gdy666/luci-app-lucky package/lucky
# 修复 luci-app-lucky 在 uhttpd 下因内存限制导致二进制调用静默失败
log "lucky: 修复 uhttpd 内存限制"
LUCKY_CTRL=package/lucky/luci-app-lucky/luasrc/controller/lucky.lua
sed -i 's#luci.sys.exec("/usr/bin/lucky -info")#luci.sys.exec("ulimit -v unlimited 2>/dev/null; /usr/bin/lucky -info")#' "$LUCKY_CTRL"
sed -i 's#luci.sys.exec("lucky -baseConfInfo -cd "..configPath)#luci.sys.exec("ulimit -v unlimited 2>/dev/null; lucky -baseConfInfo -cd "..configPath)#' "$LUCKY_CTRL"
sed -i 's#luci.sys.exec(cmd)#luci.sys.exec("ulimit -v unlimited 2>/dev/null; "..cmd)#' "$LUCKY_CTRL"

# --- quickfile ---
log "克隆 quickfile"
git clone --depth=1 https://github.com/sbwml/luci-app-quickfile package/quickfile

# --- bandix ---
log "克隆 bandix"
git clone --depth=1 https://github.com/timsaya/luci-app-bandix package/bandix
git clone --depth=1 https://github.com/timsaya/openwrt-bandix package/openwrt-bandix

# ============================================================
# 注入 Nginx Quickfile 修复
# ============================================================
log "注入 Nginx Quickfile 修复"
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-fix-nginx-quickfile << 'EOF'
#!/bin/sh
uci set nginx.global.uci_enable='true'
uci del nginx._lan; uci del nginx._redirect2ssl
uci add nginx server; uci rename nginx.@server[0]='_lan'
uci set nginx._lan.server_name='_lan'
uci add_list nginx._lan.listen='80 default_server'
uci add_list nginx._lan.listen='[::]:80 default_server'
uci add_list nginx._lan.include='conf.d/*.locations'
uci set nginx._lan.access_log='off'
uci commit nginx
/etc/init.d/nginx restart
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-fix-nginx-quickfile
