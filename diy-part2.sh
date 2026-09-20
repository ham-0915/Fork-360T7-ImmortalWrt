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

# ============================================================
# 克隆第三方插件
# ============================================================

# ============================================================
# Golang + lang rust（部分插件编译依赖）
# ============================================================
log "替换 Golang → 27.x"
rm -rf feeds/packages/lang/golang
git clone --depth=1 -b 27.x https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

# log "修复 lang-rust 404 问题"
# rm -rf feeds/packages/lang/rust
# git clone --depth=1 https://github.com/sbwml/packages_lang_rust feeds/packages/lang/rust

# ============================================================
# 克隆官方 Passwall + 依赖
# ============================================================
log "克隆官方 Passwall"
# 移除 openwrt feeds 自带的核心库
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,v2ray-plugin,xray-plugin,geoview,shadow-tls}
# 移除 openwrt feeds 过时的luci版本
rm -rf feeds/luci/applications/luci-app-passwall

git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git package/passwall-packages
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall.git package/passwall

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
