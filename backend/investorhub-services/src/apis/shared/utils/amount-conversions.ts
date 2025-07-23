import { ethers } from 'ethersV6';

/**
 * Convert a readable amount to raw amount (wei/smallest unit)
 * @param amount - The readable amount (e.g., 1.5 ETH)
 * @param decimals - The number of decimal places for the token
 * @returns The raw amount as a bigint
 */
export function fromReadableAmount(amount: number, decimals: number): bigint {
  return ethers.parseUnits(amount.toString(), decimals);
}

/**
 * Convert a raw amount to readable amount
 * @param rawAmount - The raw amount (wei/smallest unit)
 * @param decimals - The number of decimal places for the token
 * @returns The readable amount as a string
 */
export function toReadableAmount(rawAmount: bigint | number, decimals: number): string {
  return ethers.formatUnits(rawAmount, decimals);
} 