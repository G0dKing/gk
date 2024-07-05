#!/bin/bash

chk_sudo() {
    if [[ "$UID" -ne 0 ]]; then
        exec sudo "$0" "$@"
    fi
}

chk_wsl() {
    if grep -Ei '(Microsoft|WSL)' /proc/version > /dev/null 2>&1; then
        export is_wsl=1
    else
        export is_wsl=0
    fi
}

install_basics() {
    local tools=(
        curl
        wget
        git
        tar
        unzip
        net-tools
        jq
        vim
        htop
        dos2unix
        tree
        grep
        thefuck
        aria2
        neofetch
        nginx
        python3-full
        certbot
        python3-certbot-nginx
        fzf
        nano
        ssh
    )
    echo "Checking Packages..."
    echo
    for tool in "${tools[@]}"; do
        if ! command -v $tool &>/dev/null; then
            echo "Installing -- $tool"
            sudo apt install -y $tool &>/dev/null || { echo "Failed -- $tool"; return 1; }
        else
            echo "Installed -- $tool"
        fi
    done
}

install_nvm() {
    echo "Installing Node Version Manager..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash &>/dev/null
    echo "Success."
}

install_conda() {
    echo "Installing Conda..."
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O Miniconda3-latest-Linux-x86_64.sh &>/dev/null
    bash Miniconda3-latest-Linux-x86_64.sh -b
    rm Miniconda3-latest-Linux-x86_64.sh
    echo "Success."
}

install_bun() {
    echo "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash &>/dev/null
    echo "Success."
}

install_rust() {
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y &>/dev/null
    echo "Success."
}

enable_systemd() {
    if [[ $is_wsl -eq 1 ]]; then
        sudo bash -c 'echo -e "[boot]\nsystemd=true" >> /etc/wsl.conf'
    fi
}

_install() {
    local here=$(pwd)
    local dir=$HOME/g0dking
    local dir2="$dir/init"

    chk_sudo "$@"
    chk_wsl

    sudo apt update || { echo "Error: Could not update system packages."; exit 1; }
    chown -R $USER:$USER "$dir" || { echo "Error: Could not modify permissions."; exit 1; }
    cp "$dir2/bashrc" $HOME/.bashrc && sudo cp "$dir2/nanorc" /etc || { echo "Error: Could not copy files."; exit 1; }
    source ~/.bashrc

    enable_systemd

    install_basics
    install_nvm
    install_conda
    install_bun
    install_rust

    return 0
}

uid=$(id -u)
clear
echo "Initializing Environment..."
_install "$@"
wait
clear
echo "Configuration Completed Successfully."
sleep 3
echo
echo "Press ENTER to apply changes (note: this will reload the current shell)."
read -r
exec bash
