import { ethers } from 'ethersV6';
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class BlockHelper {
  private readonly logger = new Logger(BlockHelper.name);
  private provider: ethers.JsonRpcProvider;

  constructor(private readonly configService: ConfigService) {
    const rpcUrl = this.configService.get<string>('ETHEREUM_RPC_URL');
    if (!rpcUrl) {
      throw new Error('ETHEREUM_RPC_URL environment variable is not set');
    }
    this.provider = new ethers.JsonRpcProvider(rpcUrl);
  }

  /**
   * Get the current block number
   * @returns Promise<number> The current block number
   */
  async getCurrentBlockNumber(): Promise<number> {
    try {
      const blockNumber = await this.provider.getBlockNumber();
      return blockNumber;
    } catch (error) {
      this.logger.error(`Failed to get current block number: ${error.message}`);
      throw error;
    }
  }

  /**
   * Get the timestamp of a specific block
   * @param blockNumber The block number to get the timestamp for
   * @returns Promise<number> The block timestamp
   */
  async getBlockTimestamp(blockNumber: number): Promise<number> {
    try {
      const block = await this.provider.getBlock(blockNumber);
      if (!block) {
        throw new Error(`Block ${blockNumber} not found`);
      }
      return block.timestamp;
    } catch (error) {
      this.logger.error(`Failed to get block timestamp for block ${blockNumber}: ${error.message}`);
      throw error;
    }
  }

  /**
   * Get the current block timestamp
   * @returns Promise<number> The current block timestamp
   */
  async getCurrentBlockTimestamp(): Promise<number> {
    try {
      const blockNumber = await this.getCurrentBlockNumber();
      return this.getBlockTimestamp(blockNumber);
    } catch (error) {
      this.logger.error(`Failed to get current block timestamp: ${error.message}`);
      throw error;
    }
  }
} 