import { EIP1193Provider } from "@privy-io/react-auth";
import { ethers } from "ethers";

const MIN_TICK = -887272;
const MAX_TICK = 887272;

const IUniswapV3PoolABI = [
    "function tickSpacing() external view returns (int24)",
];

// Convert tick to price (1.0001^tick)
export function tickToPrice(tick: number): number {
    return Math.pow(1.0001, tick);
}

// Convert price to tick
export function priceToTick(price: number): number {
    return Math.log(price) / Math.log(1.0001);
}

// Get the nearest valid tick for a given price and tick spacing
export function getNearestValidTick(price: number, tickSpacing: number): number {
    const tick = priceToTick(price);
    return Math.round(tick / tickSpacing) * tickSpacing;
}

// Check if a tick is valid for a given tick spacing
export function isValidTick(tick: number, tickSpacing: number): boolean {
    return tick % tickSpacing === 0;
}

export async function calculateTickValues(provider: EIP1193Provider, poolAddress: string, isTheSameNetwork: boolean) {
    try {
        console.log('Is the same network:', isTheSameNetwork);
        const ethersProvider = new ethers.BrowserProvider(provider);
        const poolContract = new ethers.Contract(poolAddress, IUniswapV3PoolABI, ethersProvider);
        const tickSpacing = await poolContract.tickSpacing();

        const spacing = Number(tickSpacing);

        const minTick = Math.ceil(MIN_TICK / spacing) * spacing;
        const maxTick = Math.floor(MAX_TICK / spacing) * spacing;

        return {
            minTick: minTick,
            maxTick: maxTick,
            tickSpacing: spacing
        };
    } catch (error) {
        console.error('Error calculating tick values:', error);
        throw error;
    }
}