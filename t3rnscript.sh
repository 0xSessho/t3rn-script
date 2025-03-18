#!/bin/bash

# Download the file and extract it
wget https://github.com/t3rn/executor-release/releases/download/v0.53.1/executor-linux-v0.53.1.tar.gz
tar -xvzf executor-linux-v0.53.1.tar.gz

# Navigate to the correct directory
cd executor/executor/bin

# Environment variable configuration
export ENVIRONMENT=testnet
export LOG_LEVEL=debug
export LOG_PRETTY=false
export EXECUTOR_PROCESS_ORDERS=true
export EXECUTOR_PROCESS_CLAIMS=true

# Ask the user to input their private key (visible input)
echo "Please enter your private key:"
read PRIVATE_KEY_LOCAL
export PRIVATE_KEY_LOCAL

# Inform the user that the private key has been successfully saved
echo "Your private key has been successfully saved."

# Configure enabled networks
export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn,unichain-sepolia'

# Ask the user to choose whether they want to use the T3RN API or RPC
echo "Please select an option:"
echo "1) API (T3RN)"
echo "2) RPC"
read API_OR_RPC

if [ "$API_OR_RPC" -eq 1 ]; then
    export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true
elif [ "$API_OR_RPC" -eq 2 ]; then
    export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false
else
    echo "Invalid selection. Please choose either 1 or 2."
    exit 1
fi

export EXECUTOR_PROCESS_ORDERS_API_ENABLED=false
export EXECUTOR_ENABLE_BATCH_BIDING=true
export EXECUTOR_PROCESS_BIDS_ENABLED=true
export EXECUTOR_MAX_L3_GAS_PRICE=1000

# Set RPC endpoints for different networks
export RPC_ENDPOINTS='{
    "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
    "arbt": ["https://arbitrum-sepolia.drpc.org/", "https://sepolia-rollup.arbitrum.io/rpc"],
    "bast": ["https://base-sepolia-rpc.publicnode.com/", "https://base-sepolia.drpc.org/"],
    "opst": ["https://sepolia.optimism.io/", "https://optimism-sepolia.drpc.org/"],
    "unit": ["https://unichain-sepolia.drpc.org/", "https://sepolia.unichain.org/"]
}'

# Run the executor
./executor
