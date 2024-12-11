#!/bin/bash

# ======================
# 定义颜色变量
# ======================
RED='\e[31m'      # 红色
GREEN='\e[32m'    # 绿色
YELLOW='\e[33m'   # 黄色
BLUE='\e[34m'     # 蓝色
BOLD='\e[1m'      # 加粗
RESET='\e[0m'     # 重置颜色

# ======================
# 定义 Linux 发行版和包管理器映射
# ======================
declare -A PACKAGE_MANAGERS=(
    [ubuntu]="apt snap"
    [debian]="apt"
    [centos]="yum"
    [fedora]="dnf"
    [arch]="pacman"
    [opensuse]="zypper"
)

# ======================
# 检查 Linux 发行版
# ======================
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    echo -e "${GREEN}${BOLD}检测到的 Linux 发行版: $NAME${RESET}"
    PACKAGE_MANAGERS_FOR_DISTRO=${PACKAGE_MANAGERS[$DISTRO]}
    if [ -z "$PACKAGE_MANAGERS_FOR_DISTRO" ]; then
        echo -e "${YELLOW}${BOLD}未找到与此发行版匹配的包管理器，将尝试手动指定安装方法。${RESET}"
    else
        echo -e "${BLUE}${BOLD}将依次尝试以下包管理器: $PACKAGE_MANAGERS_FOR_DISTRO${RESET}"
    fi
else
    echo -e "${RED}${BOLD}无法确定 Linux 发行版。${RESET}"
    DISTRO="unknown"
    PACKAGE_MANAGERS_FOR_DISTRO=""
fi

# ======================
# 安装缺失的包管理器（如 snap）
# ======================
install_package_manager() {
    PACKAGE_MANAGER=$1
    if ! command -v $PACKAGE_MANAGER >/dev/null 2>&1; then
        echo -e "${YELLOW}${BOLD}$PACKAGE_MANAGER 未安装，正在安装...${RESET}"
        case $PACKAGE_MANAGER in
            snap)
                echo -e "${YELLOW}执行命令: sudo apt update && sudo apt install -y snapd && sudo systemctl enable --now snapd.socket${RESET}"
                sudo apt update
                sudo apt install -y snapd
                sudo systemctl enable --now snapd.socket
                echo -e "${GREEN}${BOLD}$PACKAGE_MANAGER 已成功安装。${RESET}"
                ;;
            *)
                echo -e "${RED}${BOLD}不支持的包管理器安装: $PACKAGE_MANAGER${RESET}"
                ;;
        esac
    else
        echo -e "${GREEN}${BOLD}$PACKAGE_MANAGER 已安装。${RESET}"
    fi
}

# ======================
# 通用软件安装函数
#   参数:
#   1. 软件名称
#   2. 命令名称(用于检测安装是否成功)
#   3. 安装类型("package"或"script")
#   4. 对应安装命令或脚本命令
# ======================
install_software() {
    SOFTWARE_NAME=$1
    COMMAND_NAME=$2
    INSTALL_TYPE=$3
    INSTALL_CMD=$4

    # ---- 检测软件是否已安装 ----
    if ! command -v $COMMAND_NAME >/dev/null 2>&1; then
        echo -e "${YELLOW}${BOLD}$SOFTWARE_NAME 未安装，正在安装...${RESET}"

        # ---- 使用包管理器安装 ----
        if [ "$INSTALL_TYPE" == "package" ]; then
            for PACKAGE_MANAGER in $PACKAGE_MANAGERS_FOR_DISTRO; do
                if command -v $PACKAGE_MANAGER >/dev/null 2>&1; then
                    case $PACKAGE_MANAGER in
                        apt)
                            echo -e "${YELLOW}执行命令: sudo apt update && sudo apt install -y $SOFTWARE_NAME${RESET}"
                            sudo apt update
                            sudo apt install -y $SOFTWARE_NAME
                            ;;
                        snap)
                            echo -e "${YELLOW}执行命令: sudo snap install $SOFTWARE_NAME${RESET}"
                            sudo snap install $SOFTWARE_NAME
                            ;;
                        yum)
                            echo -e "${YELLOW}执行命令: sudo yum install -y $SOFTWARE_NAME${RESET}"
                            sudo yum install -y $SOFTWARE_NAME
                            ;;
                        dnf)
                            echo -e "${YELLOW}执行命令: sudo dnf install -y $SOFTWARE_NAME${RESET}"
                            sudo dnf install -y $SOFTWARE_NAME
                            ;;
                        pacman)
                            echo -e "${YELLOW}执行命令: sudo pacman -S --noconfirm $SOFTWARE_NAME${RESET}"
                            sudo pacman -S --noconfirm $SOFTWARE_NAME
                            ;;
                        zypper)
                            echo -e "${YELLOW}执行命令: sudo zypper install -y $SOFTWARE_NAME${RESET}"
                            sudo zypper install -y $SOFTWARE_NAME
                            ;;
                        *)
                            echo -e "${RED}${BOLD}不支持的包管理器：$PACKAGE_MANAGER。${RESET}"
                            ;;
                    esac

                    # ---- 检测安装结果 ----
                    if command -v $COMMAND_NAME >/dev/null 2>&1; then
                        echo -e "${GREEN}${BOLD}$SOFTWARE_NAME 已成功安装。${RESET}"
                        return
                    else
                        echo -e "${YELLOW}${BOLD}使用 $PACKAGE_MANAGER 安装 $SOFTWARE_NAME 失败，尝试下一个包管理器...${RESET}"
                    fi
                else
                    echo -e "${YELLOW}${BOLD}未找到 $PACKAGE_MANAGER，尝试安装它。${RESET}"
                    install_package_manager $PACKAGE_MANAGER
                fi
            done
            echo -e "${RED}${BOLD}所有包管理器均无法安装 $SOFTWARE_NAME。${RESET}"

        # ---- 使用脚本安装 ----
        elif [ "$INSTALL_TYPE" == "script" ]; then
            echo -e "${YELLOW}执行命令: $INSTALL_CMD${RESET}"
            eval "$INSTALL_CMD"
            if command -v $COMMAND_NAME >/dev/null 2>&1; then
                echo -e "${GREEN}${BOLD}$SOFTWARE_NAME 已成功安装。${RESET}"
            else
                echo -e "${RED}${BOLD}安装 $SOFTWARE_NAME 失败，请检查安装命令或网络连接。${RESET}"
            fi
        else
            echo -e "${RED}${BOLD}未知的安装类型：$INSTALL_TYPE。${RESET}"
        fi
    else
        echo -e "${GREEN}${BOLD}$SOFTWARE_NAME 已安装。${RESET}"
    fi
}

# ======================
# 开始安装各类软件
# ======================

# ---- 安装 lsd ----
install_software lsd lsd package

# ---- 安装 exa ----
install_software exa exa package

# ---- 安装 bat ----
install_software bat batcat package

# ---- 安装 htop ----
install_software htop htop package

# ---- 安装 zoxide ----
install_software zoxide zoxide script "curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh"

# ---- 安装 fzf（zoxide 依赖） ----
install_software fzf fzf package

# ---- 安装 tcping ----
install_software tcping tcping script "wget https://github.com/pouriyajamshidi/tcping/releases/latest/download/tcping_amd64.deb -O /tmp/tcping.deb && apt install -y /tmp/tcping.deb"

# ---- 安装 exa（下载可执行文件） ----
install_software exa exa script "wget https://github.com/ogham/exa/releases/download/v0.10.1/exa-linux-x86_64-v0.10.1.zip -O /tmp/exa.zip && mkdir -p /opt/exa && unzip /tmp/exa.zip -d /opt/exa && ln -sf /opt/exa/bin/exa /usr/bin/exa"

# ======================
# 配置 zoxide 初始化
# ======================
if command -v zoxide >/dev/null 2>&1; then
    BASHRC="$HOME/.bashrc"

    # ---- 添加 zoxide 的相关注释和环境设置 ----
    if ! grep -q "# Setup zoxide" "$BASHRC"; then
        echo -e "\n# Setup zoxide" >> "$BASHRC"
    fi

    if ! grep -q "# Add zoxide binary path to PATH" "$BASHRC"; then
        echo -e "# Add zoxide binary path to PATH" >> "$BASHRC"
    fi

    # ---- 添加 /root/.local/bin 到 PATH ----
    if ! grep -q "export PATH=\$PATH:/root/.local/bin" "$BASHRC"; then
        echo -e "export PATH=\$PATH:/root/.local/bin" >> "$BASHRC"
        echo -e "${GREEN}${BOLD}已将 /root/.local/bin 添加到 PATH，并写入 .bashrc 文件。${RESET}"
    fi

    # ---- 添加 zoxide 初始化命令 ----
    if ! grep -q "zoxide init bash" "$BASHRC"; then
        echo -e "eval \"\$(zoxide init bash)\"" >> "$BASHRC"
        echo -e "${GREEN}${BOLD}已将 zoxide 初始化命令添加到 .bashrc 文件末尾。${RESET}"
    fi
fi

# ======================
# 更新 .bashrc 文件
# 添加常用别名 (alias)
# ======================
ALIAS_LIST=(
    "alias ee='exa -l'"
    "alias ea='exa -la'"
    "alias bat='batcat'"
    "alias ll='lsd -l'"
    "alias lla='lsd -la'"
)
PERSONAL_ALIAS_COMMENT="# Some personal aliases"

# 确保注释行存在，如果不存在则添加到文件末尾
if ! grep -qF "$PERSONAL_ALIAS_COMMENT" "$BASHRC"; then
    # 检查.bashrc的最后一行是否为空
    if [ -s "$BASHRC" ] && [ "$(tail -n 1 "$BASHRC")" != "" ]; then
        echo "" >> "$BASHRC"
    fi
    echo "$PERSONAL_ALIAS_COMMENT" >> "$BASHRC"
    echo -e "${GREEN}${BOLD}已在文件末尾追加 $PERSONAL_ALIAS_COMMENT${RESET}"
fi

# 接下来统一处理 alias 的追加
for ALIAS_LINE in "${ALIAS_LIST[@]}"; do
    if grep -qF "$ALIAS_LINE" "$BASHRC"; then
        echo -e "${YELLOW}${BOLD}$ALIAS_LINE 已存在于 .bashrc 中，跳过追加。${RESET}"
    else
        sed -i "/$PERSONAL_ALIAS_COMMENT/a $ALIAS_LINE" "$BASHRC"
        echo -e "${GREEN}${BOLD}已在 $PERSONAL_ALIAS_COMMENT 后追加: $ALIAS_LINE${RESET}"
    fi
done

# ======================
# 更新 .vimrc 文件
# 如果不存在则创建，并添加基础设置
# ======================
VIMRC="$HOME/.vimrc"
if [ ! -f "$VIMRC" ]; then
    touch "$VIMRC"
    echo -e "${YELLOW}${BOLD}未找到 .vimrc 文件，已创建。${RESET}"
fi

# ---- 需要写入 .vimrc 的设置项 ----
VIMRC_SETTINGS=(
    "set nu"         # 显示行号
    "set hlsearch"  # 高亮搜索
)

# ---- 添加设置项到 .vimrc ----
for SETTING in "${VIMRC_SETTINGS[@]}"; do
    if ! grep -q "$SETTING" "$VIMRC"; then
        echo "$SETTING" >> "$VIMRC"
        echo -e "${GREEN}${BOLD}已在 .vimrc 中追加 '$SETTING'。${RESET}"
    fi
done

# ======================
# 重新加载 .bashrc 并完成
# ======================
source "$BASHRC"
echo -e "${BLUE}${BOLD}设置已完成，已自动加载新的配置。${RESET}"
