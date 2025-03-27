#!/bin/bash

# Display ASCII name in 3 parts with blue and red colors
echo -e "\033[0;34m╔═══╗░░╔═══╗░░░░░░░░╔╗░╔╦═══╗"
echo -e "\033[0;31m║╔═╗║░░║╔═╗║░░░░░░░░║║░║║╔═╗║"
echo -e "\033[0;34m║║║║╠╗╔╣╚══╦══╦══╦══╣╚═╝║║░║║"
echo -e "\033[0;31m║║║║╠╬╬╩══╗║║═╣══╣══╣╔═╗║║░║║"
echo -e "\033[0;34m║╚═╝╠╬╬╣╚═╝║║═╬══╠══║║░║║╚═╝║"
echo -e "\033[0;31m╚═══╩╝╚╩═══╩══╩══╩══╩╝░╚╩═══╝"
echo -e "\033[0;34m░╔╗╔═══╗░░░░░░░░░░░░░░░░░╔╗░░"
echo -e "\033[0;31m╔╝╚╣╔═╗║░░░░░░░░░░░░░░░╔╝╚╗░"
echo -e "\033[0;34m╚╗╔╩╝╔╝╠═╦═╗░╔══╦══╦═╦╦═╩╗╔╝░"
echo -e "\033[0;31m░║║╔╗╚╗║╔╣╔╗╗║══╣╔═╣╔╬╣╔╗║║░░"
echo -e "\033[0;34m░║╚╣╚═╝║║║║║║╠══║╚═╣║║║╚╝║╚╗░"
echo -e "\033[0;31m░╚═╩═══╩╝╚╝╚╝╚══╩══╩╝╚╣╔═╩═╝░"
echo -e "\033[0;34m░░░░░░░░░░░░░░░░░░░░░░║║░░░░░"
echo -e "\033[0;31m░░░░░░░░░░░░░░░░░░░░░░╚╝░░░░░"
echo -e "\033[0m"  # Reset color to default

# Function to get the latest version from GitHub
get_latest_version() {
    echo "Fetching the latest available version..."
    LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep -oP '"tag_name": "v\K[^"]+')
    if [ -z "$LATEST_VERSION" ]; then
        echo "Could not retrieve the latest version. Using v0.53.1 by default."
        LATEST_VERSION="0.53.1"
    fi
    echo "Latest version found: v$LATEST_VERSION"
}

# Function to verify if the version exists on GitHub
verify_version() {
    VERSION_TO_CHECK=$1

    if [[ ! "$VERSION_TO_CHECK" =~ \. ]]; then
        VERSION_TO_CHECK="$VERSION_TO_CHECK.0"
    fi
    
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://github.com/t3rn/executor-release/releases/download/v$VERSION_TO_CHECK/executor-linux-v$VERSION_TO_CHECK.tar.gz")
    
    if [ "$RESPONSE" -eq 404 ]; then
        echo "Error, version not available or incorrect data."
        exit 1
    fi
}

# Function to display installation menu
choose_installation() {
    echo -e "\033[1;33mSelect the installation type:\033[0m"
    echo -e "1) \033[0;32mDefault installation (orders are processed through the t3rn API)\033[0m"
    echo -e "2) \033[0;31mCustom installation\033[0m"
    read -p "Enter your option (1 or 2): " INSTALLATION_OPTION
}

# Function to ask for the version to install
choose_version() {
    echo -e "\033[1;33mSelect the version to install:\033[0m"
    echo -e "1) \033[0;32mLatest available version\033[0m"
    echo -e "2) \033[0;31mSpecific version\033[0m"
    read -p "Enter your option (1 or 2): " VERSION_OPTION

    if [ "$VERSION_OPTION" -eq 1 ]; then
        get_latest_version
    elif [ "$VERSION_OPTION" -eq 2 ]; then
        read -p "Enter the specific version (example: 0.53.1): " LATEST_VERSION
        verify_version "$LATEST_VERSION"
    else
        echo "Invalid selection. Exiting."
        exit 1
    fi
}

# Choose version before installation
choose_version

# Download and extract the file
DOWNLOAD_URL="https://github.com/t3rn/executor-release/releases/download/v$LATEST_VERSION/executor-linux-v$LATEST_VERSION.tar.gz"
echo "Downloading: $DOWNLOAD_URL"
wget "$DOWNLOAD_URL"
tar -xvzf "executor-linux-v$LATEST_VERSION.tar.gz"

# Navigate to the correct directory
cd executor/executor/bin || { echo "Error: Could not access the directory."; exit 1; }

# Initial setup
choose_installation

# Fixed variables
export ENVIRONMENT=testnet
export LOG_LEVEL=debug
export LOG_PRETTY=false

# Default option
if [ "$INSTALLATION_OPTION" -eq 1 ]; then
    echo "Default installation selected."
    export EXECUTOR_PROCESS_ORDERS=true
    export EXECUTOR_PROCESS_CLAIMS=true
    export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn,unichain-sepolia'
    export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true
    export EXECUTOR_PROCESS_ORDERS_API_ENABLED=false
    export EXECUTOR_ENABLE_BATCH_BIDING=true
    export EXECUTOR_PROCESS_BIDS_ENABLED=true
    export EXECUTOR_MAX_L3_GAS_PRICE=1000
else
    echo "Custom installation selected."
    echo -e "\033[1;33mDo you want to use the T3RN API to process pending orders?\033[0m"
    echo -e "1) \033[0;32mYes\033[0m"
    echo -e "2) \033[0;31mNo\033[0m"
    read -p "Enter your option (1 or 2): " API_OPTION
    
    if [ "$API_OPTION" -eq 1 ]; then
        export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true
    elif [ "$API_OPTION" -eq 2 ]; then
        export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false
    else
        echo "Invalid selection. Exiting."
        exit 1
    fi
fi

# Request private key
echo -e "\033[1;33mEnter your private key:\033[0m"
read -s PRIVATE_KEY_LOCAL
export PRIVATE_KEY_LOCAL

echo "Configuration complete. Running the node..."
./executor
