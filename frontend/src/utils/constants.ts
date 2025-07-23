export const DIAMOND_CONTRACT_ADDRESS = "0x5D8DF8b23bD15D8c01e07dE59114E7147F8C828f"
export const QUOTER_CONTRACT_ADDRESS = '0xEd1f6473345F45b75F8179591dd5bA1888cf2FB3'

// Uniswap V3 Fee Tiers
export const FEE_TIERS = {
    LOWEST: 100,    // 0.01%
    LOW: 500,       // 0.05%
    MEDIUM: 3000,   // 0.3%
    HIGH: 10000     // 1%
} as const;

export const ALL_FEE_TIERS = Object.values(FEE_TIERS);

import { NetworkConfig } from '../interfaces/networkconfig';

export const NETWORKS_CONFIGS: Record<string, NetworkConfig> = {
    "eip155:11155111": {
        usdToken: {
            address: '0x1c7d4b196cb0c7b01d743fbc6116a902379c7238',
            decimals: 6,
        },
        quoterContract: "0xEd1f6473345F45b75F8179591dd5bA1888cf2FB3",
        name: "Sepolia"
    },
    "eip155:84532": {
        usdToken: {
            address: '0x0000000000000000000000000000000000000000',
            decimals: 6,
        },
        quoterContract: "0xC5290058841028F1614F3A6F0F5816cAd0df5E27",
        name: "Base Sepolia"
    }
}