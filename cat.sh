#!/bin/bash

# Colors for styling and emoji support in logs
COLOR_RED="\e[31m"
COLOR_GREEN="\e[32m"
COLOR_YELLOW="\e[33m"
COLOR_BLUE="\e[34m"
COLOR_RESET="\e[0m"
COLOR_CYAN="\e[36m"

# Function to display and open links
display_and_open_links() {
    echo -e "${COLOR_BLUE}Welcome to WibuCrypto${COLOR_RESET}"
    echo -e "============================${COLOR_YELLOW}CAT_Protocol${COLOR_RESET}============================"
    echo -e "Telegram : https://t.me/wibuairdrop142"
    echo -e "Website  : https://wibucrypto.pro/"
    echo -e "Youtube  : https://www.youtube.com/@wibucrypto2201"
    echo -e "Discord  : https://discord.gg/krCx2ssjGa"
    echo -e "Tiktok   : https://www.tiktok.com/@waibucrypto"
}

# Function to log messages with styling and emoji support
log() {
    echo -e "${COLOR_CYAN}$1${COLOR_RESET}"
}

# Error handling with emoji support
handle_error() {
    echo -e "${COLOR_RED}❌ Error: $1${COLOR_RESET}"
    exit 1
}

# Check if running as root user
check_root() {
    [[ $EUID != 0 ]] && handle_error "Not currently root user. Please switch to root account or use 'sudo su' to obtain temporary root privileges."
}

# Function to install environment dependencies and set up full node
install_env_and_full_node() {
    check_root
    log "Updating and upgrading the system..."
    sudo apt update && sudo apt upgrade -y || handle_error "Failed to update and upgrade the system."

    log "Installing required tools and libraries..."
    sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git make ncdu unzip zip docker.io -y || handle_error "Failed to install required dependencies."

    log "Installing Docker Compose..."
    VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*\d')
    DESTINATION=/usr/local/bin/docker-compose
    sudo curl -L https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m) -o $DESTINATION || handle_error "Failed to download Docker Compose."
    sudo chmod 755 $DESTINATION || handle_error "Failed to set permissions for Docker Compose."

    log "Installing Node.js, npm, and Yarn..."
    sudo apt-get install npm -y || handle_error "Failed to install npm."
    sudo npm install n -g || handle_error "Failed to install Node.js version manager."
    sudo n stable || handle_error "Failed to install the stable version of Node.js."
    sudo npm i -g yarn || handle_error "Failed to install Yarn."

    log "Cloning CAT Token Box project..."
    git clone https://github.com/CATProtocol/cat-token-box || handle_error "Failed to clone CAT Token Box repository."
    cd cat-token-box || handle_error "Failed to navigate to cat-token-box directory."

    log "Installing project dependencies and building the project..."
    sudo yarn install || handle_error "Failed to install dependencies."
    sudo yarn build || handle_error "Failed to build the project."

    log "Setting up Docker environment and starting services..."
    cd ./packages/tracker/ || handle_error "Failed to navigate to tracker package."
    sudo chmod 777 docker/data || handle_error "Failed to set permissions for data directory."
    sudo chmod 777 docker/pgdata || handle_error "Failed to set permissions for pgdata directory."
    sudo docker-compose up -d || handle_error "Failed to start Docker services."

    log "Building and running Docker image for the tracker..."
    cd ../../ || handle_error "Failed to navigate back to root directory."
    sudo docker build -t tracker:latest . || handle_error "Failed to build Docker image."
    sudo docker run -d --name tracker --add-host="host.docker.internal:host-gateway" \
        -e DATABASE_HOST="host.docker.internal" \
        -e RPC_HOST="host.docker.internal" \
        -p 3000:3000 tracker:latest || handle_error "Failed to run Docker container for tracker."

    log "Creating the configuration file for CAT Token Box..."
    echo '{
      "network": "fractal-mainnet",
      "tracker": "http://127.0.0.1:3000",
      "dataDir": ".",
      "maxFeeRate": 30,
      "rpc": {
          "url": "http://127.0.0.1:8332",
          "username": "bitcoin",
          "password": "opcatAwesome"
      }
    }' > ~/cat-token-box/packages/cli/config.json || handle_error "Failed to create config.json."

    log "Creating mint script..."
    echo '#!/bin/bash

    command="sudo yarn cli mint -i 45ee725c2c5993b3e4d308842d87e973bf1951f5f7a804b21e4dd964ecd12d6b_0 5"

    while true; do
        $command

        if [ $? -ne 0 ]; then
            echo "Command execution failed, exiting loop"
            exit 1
        fi

        sleep 1
    done' > ~/cat-token-box/packages/cli/mint_script.sh || handle_error "Failed to create mint_script.sh."
    chmod +x ~/cat-token-box/packages/cli/mint_script.sh || handle_error "Failed to set executable permissions for mint_script.sh."
}

# Function to create a wallet
create_wallet() {
    log "Creating a new wallet..."
    cd ~/cat-token-box/packages/cli || handle_error "Failed to navigate to CLI package."
    sudo yarn cli wallet create || handle_error "Failed to create a new wallet."
    sudo yarn cli wallet address || handle_error "Failed to retrieve the wallet address."
    log "Please save the wallet address and mnemonic phrase created above."
}

# Function to start the minting process
start_mint_cat() {
    log "Starting the minting process..."
    cd ~/cat-token-box/packages/cli || handle_error "Failed to navigate to CLI package."
    bash ~/cat-token-box/packages/cli/mint_script.sh || handle_error "Minting process failed."
}

# Function to check node synchronization log
check_node_log() {
    log "Checking the node synchronization log..."
    docker logs -f --tail 100 tracker || handle_error "Failed to fetch node logs."
}

# Function to check wallet balance
check_wallet_balance() {
    log "Checking wallet balance..."
    cd ~/cat-token-box/packages/cli || handle_error "Failed to navigate to CLI package."
    sudo yarn cli wallet balances || handle_error "Failed to retrieve wallet balances."
}

# Display main menu
echo -e "\n
${COLOR_GREEN}Welcome_WIBU_CRYPTO${COLOR_RESET}
This script is completely free and open source.
Please choose an operation as needed:
1. Install dependencies and full node
2. Create wallet
3. Check node synchronization log
4. Check wallet balance ( After this step got 100% then press 5 )
5. Start minting CAT
"

# Get user selection and perform corresponding operation
read -e -p "Please enter your choice: " num
case "$num" in
1)
    install_env_and_full_node
    ;;
2)
    create_wallet
    ;;
3)
    check_node_log
    ;;
4)
    check_wallet_balance
    ;;
5)
    start_mint_cat
    ;;
*)
    handle_error "Invalid option. Please enter a valid number."
    ;;
esac
