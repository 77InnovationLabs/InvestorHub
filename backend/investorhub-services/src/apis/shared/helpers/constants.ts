import { NetworkConfig } from "../interfaces/NetworkConfig";

// Uniswap V3 Fee Tiers
export const FEE_TIERS = {
  LOWEST: 100,    // 0.01%
  LOW: 500,       // 0.05%
  MEDIUM: 3000,   // 0.3%
  HIGH: 10000     // 1%
} as const;

export const ALL_FEE_TIERS = Object.values(FEE_TIERS);

export const NETWORKS_CONFIGS: { [key: string]: NetworkConfig } = {
  'eip155:11155111': {
    providerUrl: 'https://gateway.tenderly.co/public/sepolia',
    positionManagerAddress: '0x1238536071E1c677A632429e3655c799b22cDA52',
    factoryAddress: '0x0227628f3F023bb0B980b67D528571c95c6DaC1c',
    quoterContract: '0xEd1f6473345F45b75F8179591dd5bA1888cf2FB3',
    usdToken: {
      address: '0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238', // USDC on Sepolia
      symbol: 'USDC',
      decimals: 6
    }
  },
  'eip155:84532': {
    providerUrl: 'https://sepolia.base.org',
    positionManagerAddress: '0x4B8C80fBcB71E4b38A8ed8c0c3d4b4d6c83f5c8e',
    factoryAddress: '0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24',
    quoterContract: '0xC5290058841028F1614F3A6F0F5816cAd0df5E27',
    usdToken: {
      address: '0x036cbd53842c5426634e7929541ec2318f3dcf7e', // USDC on Base Sepolia
      symbol: 'USDC',
      decimals: 6
    }
  },
  'eip155:1': {
    providerUrl: 'https://eth.llamarpc.com',
    positionManagerAddress: '0xC36442b4a4522E871399CD717aBDD847Ab11FE88',
    factoryAddress: '0x1F98431c8aD98523631AE4a59f267346ea31F984',
    quoterContract: '0x61fFE014bA17989E743c5F6cB21bF9697530B21e',
    usdToken: {
      address: '0xA0b86a33E6441b8c4C8C8C8C8C8C8C8C8C8C8C8C', // USDC on Ethereum mainnet
      symbol: 'USDC',
      decimals: 6
    }
  },
  'eip155:8453': {
    providerUrl: 'https://mainnet.base.org',
    positionManagerAddress: '0x03a520b7C8bF7E5F4A2b7F3C8F8C8F8C8F8C8F8C',
    factoryAddress: '0x33128a8fC17869897dcE68Ed026d694621f6FDfD',
    quoterContract: '0x3d4e44Eb1374240CE5F1B871ab261CD16335B76a',
    usdToken: {
      address: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913', // USDC on Base mainnet
      symbol: 'USDC',
      decimals: 6
    }
  },
};