#!/bin/bash


linux_essentials() {
    echo "Installing linux essentials: git, curl, build-essential, etc..."
    sudo apt install -y \
        git \
        curl \
        wget \
        build-essential \
        unzip \
        zip \
        gnupg \
        ca-certificates \
        htop \
        tree \
        jq \
        ufw \
        openssh-client
}

install_node_nvm() {
    echo "Installing NVM (Node Version Manager)..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

    # Source NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    echo "Installing Node.js v24..."
    nvm install 24
    nvm alias default 24
    nvm use 24

    echo "Node version: $(node -v)"
    echo "NPM version: $(npm -v)"

    echo "NVM and Node.js installed. Please restart your terminal or run 'source ~/.bashrc' to use them."
}

install_caddy() {
    echo "Installing Caddy web server..."
    sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
    chmod o+r /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    chmod o+r /etc/apt/sources.list.d/caddy-stable.list
    sudo apt install -y caddy
    echo "Caddy installed and running."
}

install_haproxy() {
    echo "Installing HAProxy..."
    sudo apt install -y haproxy
    sudo systemctl enable haproxy
    sudo systemctl start haproxy

    echo "HAProxy version: $(haproxy -v)"
    echo "HAProxy status: $(systemctl is-active haproxy)"
}

install_nginx() {
    echo "Installing NGINX..."
    sudo apt install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx

    echo "NGINX version: $(nginx -v 2>&1)"
}

install_uv() {
    echo "Installing uv (Python package manager)..."
    sudo apt install -y curl python3 python3-pip
    curl -Ls https://astral.sh/uv/install.sh | bash

    # Add uv to the PATH
    export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

    echo "uv version: $(uv --version)"
    echo "uv installed. Please restart your terminal or run 'source ~/.bashrc' to use it."
}

setup_venv() {
    echo "Setting up Python virtual environment in './venv'..."
    if [ ! -f "$(command -v uv)" ]; then
        echo "Error: 'uv' command not found. Please run the 'install_uv' option first."
        return 1
    fi

    if [ ! -d "venv" ]; then
        # Add uv to path just in case it was installed
        export PATH="$HOME/.local/bin:$PATH"
        uv venv
        echo "Virtual environment created."
    else
        echo "Virtual environment './venv' already exists."
    fi
}


install_python_packages_with_uv() {
    if [ ! -d "venv" ]; then
        echo "Error: Virtual environment not found. Please run 'setup_venv' first."
        return 1
    fi

    echo "Activating virtual environment..."
    source venv/bin/activate

    echo "Installing Python packages: torch, numpy, langchain..."
    uv pip install torch numpy langchain

    echo "Installed packages:"
    uv pip list | grep -E 'torch|numpy|langchain'

    deactivate
    echo "Deactivated virtual environment."
}

options=(
    "linux_essentials"
    "install_node_nvm"
    "install_caddy"
    "install_nginx"
    "install_haproxy"
    "install_uv"
    "setup_venv"
    "install_python_packages_with_uv"
    "done"
)

declare -a selections

display_menu() {
    clear
    echo "Select options to install/run. Use space to toggle, Enter to confirm selection."
    echo "----------------------------------------------------------------------------"
    for i in "${!options[@]}"; do
        if [[ " ${selections[*]} " =~ " $i " ]]; then
            echo " [x]  $i. ${options[$i]}"
        else
            echo " [ ]  $i. ${options[$i]}"
        fi
    done
    echo "----------------------------------------------------------------------------"
}

while true; do
    display_menu
    read -p "Enter number(s) to toggle, or type 'done' to execute: " input

    if [[ "$input" == "done" || "$input" == "$((${#options[@]} - 1))" ]]; then
        break
    fi

    for num in $input; do
        if [[ "$num" =~ ^[0-9]+$ && "$num" -ge 0 && "$num" -lt "$((${#options[@]} - 1))" ]]; then
            if [[ " ${selections[*]} " =~ " $num " ]]; then
                # Remove from selection
                temp_selections=()
                for item in "${selections[@]}"; do
                    [[ "$item" != "$num" ]] && temp_selections+=("$item")
                done
                selections=("${temp_selections[@]}")
            else
                # Add to selection
                selections+=("$num")
            fi
        fi
    done
done

if [ ${#selections[@]} -eq 0 ]; then
    echo "No options selected. Exiting."
    exit 0
fi

clear
echo "Executing selected functions..."
echo "Updating package lists first..."
sudo apt update -y

# Sort selections to ensure logical order if needed
IFS=$'\n' selections=($(sort -n <<<"${selections[*]}"))
unset IFS

for i in "${selections[@]}"; do
    func="${options[$i]}"
    echo
    echo "############################################################"
    echo "### Running: $func"
    echo "############################################################"

    # Execute the function
    $func
    echo "### Finished: $func"

    echo "############################################################"
    echo "### Sourcing the bashrc for reload"
    echo "############################################################"
    source ~/.bashrc
done

echo
echo "############################################################"
echo "All selected tasks are complete."
echo "############################################################"
