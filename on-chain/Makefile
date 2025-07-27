# Makefile for Foundry project

# Load environment variables from .env file
include .env
export $(shell sed 's/=.*//' .env)

.PHONY: anvil build clean coverage deploy execute fork_testnet fork_mainnet forked_test format fund help install snapshot test

# Generate Keys
anvil :
	anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1 

# Build contracts
build:
	forge build --via-ir

# Clean the environment
clean:
	forge clean

# Test Coverage
coverage:
	forge coverage --report debug > coverage-report.md
	
# Deploy contract
# Use ARGS="--network ONE_OF_THE_OPTIONS_IN_THE_END_OF_THE_FILE" after the request on the terminal.
deploy:
	@forge script script/DeployInit.s.sol:DeployInit $(NETWORK_ARGS)

# Execute Interaction Scripts
# executeSwap:
# 	@forge script script/OnChainInteraction/StartSwapInteractionLINK-WETH.s.sol:StartSwapInteraction $(NETWORK_ARGS)
executeSwap:
	@forge script script/OnChainInteraction/StartSwapInteractionWETH-LINK.s.sol:StartSwapInteraction $(NETWORK_ARGS)
executeFullSwap:
	@forge script script/OnChainInteraction/StartFullSwapInteraction.s.sol:StartFullSwapInteraction $(NETWORK_ARGS)

# Initialize forked network with anvil
fork_mainnet:
	anvil --fork-url ${BASE_MAINNET_RPC}

fork_testnet:
	anvil --fork-url ${BASE_SEPOLIA_RPC}

# Execute Forked tests
forked_test:
	forge test --match-contract DiamondForked.t.sol -vvvvv

format:
	forge fmt

# Install Dependencies
install:
	forge install foundry-rs/forge-std && forge install openzeppelin/openzeppelin-contracts && forge install smartcontractkit/chainlink-brownie-contracts && forge install Uniswap/v3-core && Uniswap/v3-periphery && forge install Uniswap/swap-router-contracts

# Remove modules
remove :
	rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# Gas Snapshot
snapshot:
	forge snapshot

# Execute tests
test:
	forge test

# Update Dependencies
update:
	forge update

NETWORK_ARGS := --rpc-url http://localhost:8545 --account ANVIL_TEST --broadcast -vvv

# Change Args if is sepolia - Update according to your needs
# Update --account live_burner with your foundry encrypted key.
# Use ARGS="--network ONE_OF_THE_OPTIONS_IN_THE_END_OF_THE_FILE" after the request on the terminal.
ifeq ($(findstring --network base-sepolia,$(ARGS)),--network base-sepolia)
	NETWORK_ARGS := --rpc-url ${BASE_SEPOLIA_RPC} --account live_burner --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvv
endif

ifeq ($(findstring --network base-mainnet,$(ARGS)),--network base-mainnet)
	NETWORK_ARGS := --rpc-url ${BASE_MAINNET_RPC} --account live_burner --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvv
endif

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url ${SEPOLIA_RPC} --account live_burner --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvvv
endif

ifeq ($(findstring --network fuji,$(ARGS)),--network fuji)
	NETWORK_ARGS := --rpc-url ${AVAX_FUJI_RPC} --account live_burner --broadcast --verify --etherscan-api-key ${SNOW_TRACE_API_KEY} -vvv
endif