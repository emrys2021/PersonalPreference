#!/bin/bash

# 定义颜色变量
RED='\e[31m'      # 红色
GREEN='\e[32m'    # 绿色
YELLOW='\e[33m'   # 黄色
BLUE='\e[34m'     # 蓝色
BOLD='\e[1m'      # 加粗
RESET='\e[0m'     # 重置颜色

# 检查 Linux 发行版
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    echo -e "${GREEN}${BOLD}检测到的 Linux 发行版: $NAME${RESET}"
else
    echo -e "${RED}${BOLD}无法确定 Linux 发行版。${RESET}"
fi

# **检查 /snap/bin 是否在 PATH 中**
if [[ ":$PATH:" != *":/snap/bin:"* ]]; then
    echo -e "${YELLOW}${BOLD}将 /snap/bin 添加到 PATH${RESET}"
    # 在 .bashrc 中添加 /snap/bin 到 PATH
    echo 'export PATH=$PATH:/snap/bin' >> "$HOME/.bashrc"
    # 立即更新当前 shell 的 PATH
    export PATH=$PATH:/snap/bin
fi

# 定义一个函数用于安装软件
install_package() {
    PACKAGE_NAME=$1   # 软件包名称
    COMMAND_NAME=$2   # 软件对应的可执行命令名称

    # 使用 'command -v' 检查命令是否存在，'command -v' 会在环境变量 PATH 中搜索指定命令，如果找到则返回其路径，否则返回非零退出状态
    if ! command -v $COMMAND_NAME >/dev/null 2>&1; then
        echo -e "${YELLOW}${BOLD}$PACKAGE_NAME 未安装，正在安装...${RESET}"
        
        # 首先尝试使用 apt 包管理器进行安装
        if command -v apt >/dev/null 2>&1; then
            sudo apt update
            sudo apt install -y $PACKAGE_NAME

            # 再次检查命令是否已安装成功
            if ! command -v $COMMAND_NAME >/dev/null 2>&1; then
                echo -e "${RED}${BOLD}使用 apt 安装 $PACKAGE_NAME 失败，尝试使用 snap...${RESET}"

                # 如果 apt 安装失败，且系统中存在 snap，则尝试使用 snap 进行安装
                if command -v snap >/dev/null 2>&1; then
                    sudo snap install $PACKAGE_NAME
                    # **重新加载 PATH，以确保 snap 安装的命令可用**
                    if [[ ":$PATH:" != *":/snap/bin:"* ]]; then
                        export PATH=$PATH:/snap/bin
                    fi
                else
                    echo -e "${RED}${BOLD}未安装 snap，无法安装 $PACKAGE_NAME。${RESET}"
                fi
            else
                echo -e "${GREEN}${BOLD}$PACKAGE_NAME 已成功安装。${RESET}"
            fi
        else
            echo -e "${RED}${BOLD}未找到 apt 包管理器，尝试使用其他方法安装 $PACKAGE_NAME。${RESET}"
            # 这里可以添加其他包管理器的安装命令，例如 yum、dnf 等
        fi
    else
        echo -e "${GREEN}${BOLD}$PACKAGE_NAME 已安装。${RESET}"
    fi
}

# 安装 lsd
install_package lsd lsd

# 安装 exa
install_package exa exa

# 安装 bat（在 Ubuntu 中，bat 命令是 batcat）
install_package bat batcat

# 安装 htop
install_package htop htop

# 更新 .bashrc 文件
BASHRC="$HOME/.bashrc"
ALIASES="alias ee='exa -l'\nalias ea='exa -la'\nalias bat='batcat'"

# 检查 .bashrc 中是否存在 'alias l='ls -CF''
if grep -q "alias l='ls -CF'" "$BASHRC"; then
    # 如果存在，在该行后追加自定义的 alias
    sed -i "/alias l='ls -CF'/a $ALIASES" "$BASHRC"
    echo -e "${GREEN}${BOLD}已在 .bashrc 中追加自定义的 alias。${RESET}"
else
    # 如果不存在，将自定义的 alias 追加到文件末尾
    echo -e "$ALIASES" >> "$BASHRC"
    echo -e "${GREEN}${BOLD}已在 .bashrc 文件末尾添加自定义的 alias。${RESET}"
fi

# 更新 .vimrc 文件
VIMRC="$HOME/.vimrc"
if [ ! -f "$VIMRC" ]; then
    # 如果 .vimrc 文件不存在，则创建并追加 'set nu'
    touch "$VIMRC"
    echo -e "${YELLOW}${BOLD}未找到 .vimrc 文件，已创建。${RESET}"
fi

# 直接在 .vimrc 文件末尾追加 'set nu'，用于默认开启行号
echo "set nu" >> "$VIMRC"
echo -e "${GREEN}${BOLD}已在 .vimrc 中追加 'set nu'。${RESET}"

# 在脚本末尾添加，重新加载 .bashrc，使更改在当前 shell 中生效
source "$BASHRC"

echo -e "${BLUE}${BOLD}设置已完成，已自动加载新的配置。${RESET}"