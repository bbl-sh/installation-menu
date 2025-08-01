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
    sudo apt update -y # Ensure apt cache is updated after adding repo
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

    # Add uv to the PATH (installation script usually handles this, but good to be sure)
    export PATH="$HOME/.local/bin:$PATH"

    # Source the profile to make 'uv' available immediately in this script session
    # Note: This might not always work perfectly in all environments, but it's common practice
    # The user still needs to source their profile (e.g., .bashrc) in their terminal afterward.
    if [ -f "$HOME/.bashrc" ]; then
        source "$HOME/.bashrc"
    fi

    echo "uv version: $(uv --version)"
    echo "uv installed. Please restart your terminal or run 'source ~/.bashrc' (or equivalent) to use it."
}

setup_venv() {
    echo "Setting up Python virtual environment in './venv'..."
    # Ensure uv is available in PATH for this session
    export PATH="$HOME/.local/bin:$PATH"

    if ! command -v uv &> /dev/null; then
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

    # Ensure uv is available in PATH for this session
    export PATH="$HOME/.local/bin:$PATH"

    echo "Activating virtual environment..."
    source venv/bin/activate

    echo "Installing Python packages: torch, numpy, langchain..."
    uv pip install torch numpy langchain

    echo "Installed packages:"
    uv pip list | grep -E 'torch|numpy|langchain'

    deactivate
    echo "Deactivated virtual environment."
}

install_docker() {
    echo "Installing Docker..."
    # Add Docker's official GPG key
    sudo apt update
    sudo apt install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update

    # Install Docker Engine, CLI, Containerd, Compose plugin
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add current user to docker group (requires logout/login or new shell to take effect)
    sudo usermod -aG docker $USER

    echo "Docker installed. You might need to log out and back in, or run 'newgrp docker' in your terminal, for group changes to take effect."
    echo "Docker version: $(docker --version)"
    echo "Docker Compose version: $(docker compose version)"
}

install_pocketbase() {
    echo "Installing PocketBase..."
    # Define the PocketBase version (check https://github.com/pocketbase/pocketbase/releases for latest)
    POCKETBASE_VERSION="v0.22.23" # Update this as needed
    POCKETBASE_ARCH="linux_amd64" # Adjust if on ARM (e.g., linux_arm64)

    # Create installation directory
    POCKETBASE_DIR="$HOME/pocketbase"
    mkdir -p "$POCKETBASE_DIR"

    # Download PocketBase
    POCKETBASE_URL="https://github.com/pocketbase/pocketbase/releases/download/${POCKETBASE_VERSION}/pocketbase_${POCKETBASE_VERSION}_${POCKETBASE_ARCH}.zip"
    curl -L -o "$POCKETBASE_DIR/pocketbase.zip" "$POCKETBASE_URL"

    # Extract the binary
    unzip "$POCKETBASE_DIR/pocketbase.zip" -d "$POCKETBASE_DIR"

    # Make the binary executable
    chmod +x "$POCKETBASE_DIR/pocketbase"

    # Optional: Create a symlink for easier access (requires sudo or placing in ~/bin)
    # mkdir -p "$HOME/bin"
    # ln -sf "$POCKETBASE_DIR/pocketbase" "$HOME/bin/pocketbase"
    # echo "PocketBase installed to $POCKETBASE_DIR/pocketbase"
    # echo "Consider adding $HOME/bin to your PATH or creating a symlink in /usr/local/bin (requires sudo)."

    echo "PocketBase installed to $POCKETBASE_DIR/pocketbase"
    echo "PocketBase version: $($POCKETBASE_DIR/pocketbase --version)"
}

install_mongodb() {
    echo "Installing MongoDB..."
    # Import the MongoDB public GPG key
    curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg --dearmor -o /etc/apt/keyrings/mongodb-org-7.0.gpg

    # Ensure permissions are correct
    sudo chmod 644 /etc/apt/keyrings/mongodb-org-7.0.gpg

    # Add the MongoDB repository
    echo "deb [ arch=amd64,arm64 signed-by=/etc/apt/keyrings/mongodb-org-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME")/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list > /dev/null

    # Update package lists
    sudo apt update

    # Install MongoDB packages
    sudo apt install -y mongodb-org

    # Start and enable MongoDB service
    sudo systemctl start mongod
    sudo systemctl enable mongod

    echo "MongoDB installed and started."
    echo "MongoDB version: $(mongod --version | head -n1)"
    echo "MongoDB service status: $(systemctl is-active mongod)"
}

# --- Menu Logic ---

options=(
    "linux_essentials"
    "install_node_nvm"
    "install_caddy"
    "install_nginx"
    "install_haproxy"
    "install_uv"
    "setup_venv"
    "install_python_packages_with_uv"
    "install_docker"
    "install_pocketbase"
    "install_mongodb"
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

    # Handle multiple space-separated numbers
    for num in $input; do
        # Validate input is a number within range
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
        else
             echo "Invalid option: $num. Ignoring."
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

# Sort selections to ensure logical order if needed (optional, good practice)
IFS=$'\n' sorted_selections=($(sort -n <<<"${selections[*]}"))
unset IFS

for i in "${sorted_selections[@]}"; do
    func="${options[$i]}"
    echo
    echo "############################################################"
    echo "### Running: $func"
    echo "############################################################"

    # Execute the function
    $func
    echo "### Finished: $func"

    # Sourcing .bashrc after each function might be necessary for some changes (like PATH updates from uv or nvm)
    # but can be tricky in scripts. It's often better to handle PATH updates directly in the functions.
    # The final sourcing after the loop is usually sufficient for the user's interactive shell.
    echo "### Sourcing the bashrc for reload (may not be fully effective within script) ###"
    # Suppress errors if sourcing fails
    source ~/.bashrc 2>/dev/null || true

done

# Final sourcing for the user's shell environment
echo
echo "############################################################"
echo "### Finalizing: Sourcing ~/.bashrc for environment changes ###"
echo "############################################################"
source ~/.bashrc 2>/dev/null || echo "Warning: Could not source ~/.bashrc automatically. You might need to run 'source ~/.bashrc' manually."

echo
echo "############################################################"
echo "All selected tasks are complete."
echo "############################################################"
