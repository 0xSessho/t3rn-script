#!/bin/bash

# Display ASCII name in blue and red colors
echo -e "\033[0;34m╔═══╗░░╔═══╗░░░░░░░░╔╗░╔╦═══╗"
echo -e "\033[0;31m║╔═╗║░░║╔═╗║░░░░░░░░║║░║║╔═╗║"
echo -e "\033[0;34m║║║║╠╗╔╣╚══╦══╦══╦══╣╚═╝║║░║║"
echo -e "\033[0;31m║║║║╠╬╬╩══╗║║═╣══╣══╣╔═╗║║░║║"
echo -e "\033[0;34m║╚═╝╠╬╬╣╚═╝║║═╬══╠══║║░║║╚═╝║"
echo -e "\033[0;31m╚═══╩╝╚╩═══╩══╩══╩══╩╝░╚╩═══╝"
echo -e "\033[0m"  # Reset color

# Function to get the latest GitHub release
get_latest_version() {
    echo "Fetching the latest available version..."
    LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep -oP '"tag_name": "v\K[^"]+')
    if [ -z "$LATEST_VERSION" ]; then
        echo "Could not fetch the latest version. Using v0.53.1 by default."
        LATEST_VERSION="0.53.1"
    fi
    echo "Latest version found: v$LATEST_VERSION"
}

# Function to download and extract the executor
install_executor() {
    EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/v$LATEST_VERSION/executor-linux-v$LATEST_VERSION.tar.gz"
    EXECUTOR_ARCHIVE="executor-linux-v$LATEST_VERSION.tar.gz"

    echo "Downloading executor from $EXECUTOR_URL..."
    curl -L -o "$EXECUTOR_ARCHIVE" "$EXECUTOR_URL"

    if [ ! -f "$EXECUTOR_ARCHIVE" ]; then
        echo "Error: Failed to download executor. Exiting."
        exit 1
    fi

    echo "Extracting executor..."
    tar -xvzf "$EXECUTOR_ARCHIVE"
    chmod +x executor
    rm "$EXECUTOR_ARCHIVE"

    if [ ! -f "executor" ]; then
        echo "Error: executor file not found after extraction. Exiting."
        exit 1
    fi
}

# Function to verify if a version exists on GitHub
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

# Function to select installation type
choose_installation() {
    echo -e "\033[1;33mSelect installation type:\033[0m"
    echo -e "1) \033[0;32mDefault installation (orders are processed via T3RN API)\033[0m"
    echo -e "2) \033[0;31mCustom installation\033[0m"
    read -p "Enter your choice (1 or 2): " INSTALL_OPTION
}

# Function to choose version
choose_version() {
    echo -e "\033[1;33mSelect the version to install:\033[0m"
    echo -e "1) \033[0;32mLatest available version\033[0m"
    echo -e "2) \033[0;31mSpecific version\033[0m"
    read -p "Enter your choice (1 or 2): " VERSION_OPTION

    if [ "$VERSION_OPTION" -eq 1 ]; then
        get_latest_version
    elif [ "$VERSION_OPTION" -eq 2 ]; then
        read -p "Enter the specific version (e.g., 0.53.1): " LATEST_VERSION
        verify_version "$LATEST_VERSION"
    else
        echo "Invalid selection. Exiting."
        exit 1
    fi
}

# Choose version before installation
choose_version

# Install executor
install_executor

# Choose installation type
choose_installation

if [ "$INSTALL_OPTION" -eq 2 ]; then
    echo -e "\033[1;33mDo you want to use the T3RN API to process pending orders?\033[0m"
    echo -e "1) \033[0;32mYes\033[0m"
    echo -e "2) \033[0;31mNo\033[0m"
    read -p "Enter your choice (1 or 2): " API_OPTION
    
    if [ "$API_OPTION" -eq 1 ]; then
        export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true
    elif [ "$API_OPTION" -eq 2 ]; then
        export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false
    else
        echo "Invalid selection. Exiting."
        exit 1
    fi
fi

if [ ! -f "executor" ]; then
    echo "Error: executor file not found. Checking directory contents..."
    ls -l
    echo "Exiting."
    exit 1
fi

# Verify permissions and execute
chmod +x executor

echo "Configuration complete. Running the node..."
./executor

