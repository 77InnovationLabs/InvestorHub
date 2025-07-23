import { Network } from './network';

export interface TokenInfo {
    id: string;
    name: string;
    symbol: string;
    address: string;
    decimals: string;
    network: Network;
}

export interface PoolDayData {
    date: string;
    feesUSD: string;
    volumeUSD: string;
    tvlUSD: string;
    apr24h: string;
}

export interface PoolData {
    _id: string;
    feeTier: string;
    address: string;
    token0: TokenInfo;
    token1: TokenInfo;
    createdAtTimestamp: string;
    poolDayData: PoolDayData[];
}

export interface PoolsResponse {
    pools: PoolData[];
    blockNumber: string;
}