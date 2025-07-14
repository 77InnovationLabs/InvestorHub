import { Injectable, Logger } from '@nestjs/common';
import { ethers } from 'ethers';
import { UniswapMathService } from './uniswap-math.service';
import { PositionHoldingsDto } from './dto/position-holdings.dto';
import { UncollectedFeesDto } from './dto/uncollected-fees.dto';
import { LiquidityCalculatorDto } from './dto/liquidity-calculator.dto';
import { ERC20_ABI } from '../shared/ABIS/ERC20';
import { POSITION_MANAGER_ABI } from '../shared/ABIS/POSITION_MANAGER';
import { POOL_ABI } from '../shared/ABIS/POOL';
import { FACTORY_ABI } from '../shared/ABIS/FACTORY';
import { NetworkConfigRepository } from '../network-config/repository/network-config.repository';
import { NetworkConfig } from 'src/database/schemas/network-config.schema';

@Injectable()
export class UniswapCalculatorService {
  private readonly logger = new Logger(UniswapCalculatorService.name);

  constructor(
    private readonly uniswapMathService: UniswapMathService,
    private readonly networkConfigRepository: NetworkConfigRepository,
  ) { }

  private extractChainId(network: string): number {
    const networkSplit = network.split(':');
    if (!networkSplit || networkSplit.length !== 2) {
      throw new Error(`Invalid network format: ${network}`);
    }
    return parseInt(networkSplit[1]);
  }

  private async getNetworkConfig(network: string): Promise<NetworkConfig> {
    const chainId = this.extractChainId(network);
    const config = await this.networkConfigRepository.findByChainId(chainId);
    if (!config) {
      throw new Error(`Unsupported network: ${network}`);
    }
    return config;
  }

  private async getProvider(network: string): Promise<ethers.JsonRpcProvider> {
    const config = await this.getNetworkConfig(network);
    return new ethers.JsonRpcProvider(config.rpcUrl);
  }

  private async getPositionManagerAddress(network: string): Promise<string> {
    const config = await this.getNetworkConfig(network);
    return config.positionManagerAddress;
  }

  private async getFactoryAddress(network: string): Promise<string> {
    const config = await this.getNetworkConfig(network);
    return config.factoryAddress;
  }

  private convertBigIntToString(obj: any): any {
    if (obj === null || obj === undefined) {
      return obj;
    }

    if (typeof obj === 'bigint') {
      return obj.toString();
    }

    if (Array.isArray(obj)) {
      return obj.map(item => this.convertBigIntToString(item));
    }

    if (typeof obj === 'object') {
      const result: any = {};
      for (const key in obj) {
        if (obj.hasOwnProperty(key)) {
          result[key] = this.convertBigIntToString(obj[key]);
        }
      }
      return result;
    }

    return obj;
  }

  async getPositionHoldings(dto: PositionHoldingsDto) {
    try {
      this.logger.log(`Fetching all position holdings for owner: ${dto.ownerAddress} on network: ${dto.network}`);

      const provider = await this.getProvider(dto.network);
      const positionManagerAddress = await this.getPositionManagerAddress(dto.network);
      const factoryAddress = await this.getFactoryAddress(dto.network);

      // Get position manager contract
      const positionManager = new ethers.Contract(positionManagerAddress, POSITION_MANAGER_ABI, provider);

      // Get factory contract
      const factory = new ethers.Contract(factoryAddress, FACTORY_ABI, provider);

      // Get owner's positions
      const balance = await positionManager.balanceOf(dto.ownerAddress);
      this.logger.log(`Found ${balance} total positions for owner`);

      const allPositions: any[] = [];

      for (let i = 0; i < balance; i++) {
        try {
          const tokenId = await positionManager.tokenOfOwnerByIndex(dto.ownerAddress, i);
          const position = await positionManager.positions(tokenId);

          this.logger.debug(`Processing position ${tokenId}: tickLower=${position.tickLower}, tickUpper=${position.tickUpper}, liquidity=${position.liquidity}`);

          // Get pool address using factory
          const poolAddress = await factory.getPool(position.token0, position.token1, position.fee);

          // Check if pool exists
          if (poolAddress === ethers.ZeroAddress) {
            this.logger.warn(`Pool not found for token0: ${position.token0}, token1: ${position.token1}, fee: ${position.fee}`);
            continue;
          }

          // Get pool contract
          const poolContract = new ethers.Contract(poolAddress, POOL_ABI, provider);

          // Get pool data
          const [token0, token1, fee, slot0] = await Promise.all([
            poolContract.token0(),
            poolContract.token1(),
            poolContract.fee(),
            poolContract.slot0(),
          ]);

          const currentTick = Number(slot0.tick);
          const currentSqrtPriceX96 = slot0.sqrtPriceX96;

          this.logger.debug(`Pool data: currentTick=${currentTick}, currentSqrtPriceX96=${currentSqrtPriceX96}`);

          // Get token contracts
          const token0Contract = new ethers.Contract(token0, ERC20_ABI, provider);
          const token1Contract = new ethers.Contract(token1, ERC20_ABI, provider);

          // Get token data
          const [token0Decimals, token1Decimals, token0Symbol, token1Symbol] = await Promise.all([
            token0Contract.decimals(),
            token1Contract.decimals(),
            token0Contract.symbol(),
            token1Contract.symbol(),
          ]);

          // Calculate holdings for this position
          const result = this.uniswapMathService.calculatePositionHoldings({
            liquidity: BigInt(position.liquidity),
            tickLower: Number(position.tickLower),
            tickUpper: Number(position.tickUpper),
            currentTick,
            currentSqrtPriceX96: BigInt(currentSqrtPriceX96.toString()),
            tokensOwed0: BigInt(position.tokensOwed0),
            tokensOwed1: BigInt(position.tokensOwed1),
          });

          allPositions.push({
            tokenId: tokenId.toString(),
            poolAddress: poolAddress.toLowerCase(),
            inRange: result.inRange,
            token0Amount: result.token0Amount.toString(),
            token1Amount: result.token1Amount.toString(),
            token0AmountHuman: Number(result.token0Amount) / Math.pow(10, Number(token0Decimals)),
            token1AmountHuman: Number(result.token1Amount) / Math.pow(10, Number(token1Decimals)),
            token0Symbol,
            token1Symbol,
            token0Decimals,
            token1Decimals,
            currentTick,
            currentPrice: Math.pow(1.0001, Number(currentTick)),
          });

        } catch (error) {
          this.logger.warn(`Error processing position ${i}: ${error.message}`);
          this.logger.warn(`Error stack: ${error.stack}`);
        }
      }

      if (allPositions.length === 0) {
        return {
          message: 'No positions found for this owner',
          positions: [],
        };
      }

      return this.convertBigIntToString({
        ownerAddress: dto.ownerAddress,
        network: dto.network,
        positions: allPositions,
      });

    } catch (error) {
      this.logger.error(`Error calculating position holdings: ${error.message}`);
      throw new Error(`Failed to calculate position holdings: ${error.message}`);
    }
  }

  async getUncollectedFees(dto: UncollectedFeesDto) {
    try {
      this.logger.log(`Fetching uncollected fees for all positions of owner: ${dto.ownerAddress} on network: ${dto.network}`);

      const provider = await this.getProvider(dto.network);
      const positionManagerAddress = await this.getPositionManagerAddress(dto.network);
      const factoryAddress = await this.getFactoryAddress(dto.network);

      // Get position manager contract
      const positionManager = new ethers.Contract(positionManagerAddress, POSITION_MANAGER_ABI, provider);

      // Get factory contract
      const factory = new ethers.Contract(factoryAddress, FACTORY_ABI, provider);

      // Get owner's positions
      const balance = await positionManager.balanceOf(dto.ownerAddress);
      this.logger.log(`Found ${balance} total positions for owner`);

      const allPositions: any[] = [];

      for (let i = 0; i < balance; i++) {
        try {
          const tokenId = await positionManager.tokenOfOwnerByIndex(dto.ownerAddress, i);
          const position = await positionManager.positions(tokenId);

          // Get pool address using factory
          const poolAddress = await factory.getPool(position.token0, position.token1, position.fee);

          // Check if pool exists
          if (poolAddress === ethers.ZeroAddress) {
            this.logger.warn(`Pool not found for token0: ${position.token0}, token1: ${position.token1}, fee: ${position.fee}`);
            continue;
          }

          // Get pool contract
          const poolContract = new ethers.Contract(poolAddress, POOL_ABI, provider);

          // Get pool data
          const [token0, token1, fee, slot0, feeGrowthGlobal0, feeGrowthGlobal1] = await Promise.all([
            poolContract.token0(),
            poolContract.token1(),
            poolContract.fee(),
            poolContract.slot0(),
            poolContract.feeGrowthGlobal0X128(),
            poolContract.feeGrowthGlobal1X128(),
          ]);

          const currentTick = Number(slot0.tick);

          // Get token contracts
          const token0Contract = new ethers.Contract(token0, ERC20_ABI, provider);
          const token1Contract = new ethers.Contract(token1, ERC20_ABI, provider);

          // Get token data
          const [token0Decimals, token1Decimals, token0Symbol, token1Symbol] = await Promise.all([
            token0Contract.decimals(),
            token1Contract.decimals(),
            token0Contract.symbol(),
            token1Contract.symbol(),
          ]);

          // Get tick data for fee calculation
          const [tickLowerData, tickUpperData] = await Promise.all([
            poolContract.ticks(position.tickLower),
            poolContract.ticks(position.tickUpper),
          ]);

          const result = this.uniswapMathService.calculateUncollectedFees({
            liquidity: BigInt(position.liquidity),
            feeGrowthGlobal0X128: BigInt(feeGrowthGlobal0.toString()),
            feeGrowthGlobal1X128: BigInt(feeGrowthGlobal1.toString()),
            feeGrowthOutsideLower0X128: BigInt(tickLowerData.feeGrowthOutside0X128.toString()),
            feeGrowthOutsideLower1X128: BigInt(tickLowerData.feeGrowthOutside1X128.toString()),
            feeGrowthOutsideUpper0X128: BigInt(tickUpperData.feeGrowthOutside0X128.toString()),
            feeGrowthOutsideUpper1X128: BigInt(tickUpperData.feeGrowthOutside1X128.toString()),
            feeGrowthInside0LastX128: BigInt(position.feeGrowthInside0LastX128),
            feeGrowthInside1LastX128: BigInt(position.feeGrowthInside1LastX128),
            tokensOwed0: BigInt(position.tokensOwed0),
            tokensOwed1: BigInt(position.tokensOwed1),
            currentTick,
            tickLower: Number(position.tickLower),
            tickUpper: Number(position.tickUpper),
          });

          allPositions.push({
            tokenId: tokenId.toString(),
            poolAddress: poolAddress.toLowerCase(),
            token0Fees: result.token0Fees.toString(),
            token1Fees: result.token1Fees.toString(),
            token0FeesHuman: Number(result.token0Fees) / Math.pow(10, Number(token0Decimals)),
            token1FeesHuman: Number(result.token1Fees) / Math.pow(10, Number(token1Decimals)),
            token0Symbol,
            token1Symbol,
            token0Decimals,
            token1Decimals,
          });

        } catch (error) {
          this.logger.warn(`Error processing position ${i}: ${error.message}`);
        }
      }

      if (allPositions.length === 0) {
        return {
          message: 'No positions found for this owner',
          positions: [],
        };
      }

      return this.convertBigIntToString({
        ownerAddress: dto.ownerAddress,
        network: dto.network,
        positions: allPositions,
      });

    } catch (error) {
      this.logger.error(`Error calculating uncollected fees: ${error.message}`);
      throw new Error(`Failed to calculate uncollected fees: ${error.message}`);
    }
  }

  async getLiquidityCalculation(dto: LiquidityCalculatorDto) {
    try {
      this.logger.log(`Calculating liquidity for all positions of owner: ${dto.ownerAddress} on network: ${dto.network}`);

      const provider = await this.getProvider(dto.network);
      const positionManagerAddress = await this.getPositionManagerAddress(dto.network);
      const factoryAddress = await this.getFactoryAddress(dto.network);

      // Get position manager contract
      const positionManager = new ethers.Contract(positionManagerAddress, POSITION_MANAGER_ABI, provider);

      // Get factory contract
      const factory = new ethers.Contract(factoryAddress, FACTORY_ABI, provider);

      // Get owner's positions
      const balance = await positionManager.balanceOf(dto.ownerAddress);
      this.logger.log(`Found ${balance} total positions for owner`);

      const allPositions: any[] = [];

      for (let i = 0; i < balance; i++) {
        try {
          const tokenId = await positionManager.tokenOfOwnerByIndex(dto.ownerAddress, i);
          const position = await positionManager.positions(tokenId);

          // Get pool address using factory
          const poolAddress = await factory.getPool(position.token0, position.token1, position.fee);

          // Check if pool exists
          if (poolAddress === ethers.ZeroAddress) {
            this.logger.warn(`Pool not found for token0: ${position.token0}, token1: ${position.token1}, fee: ${position.fee}`);
            continue;
          }

          // Get pool contract
          const poolContract = new ethers.Contract(poolAddress, POOL_ABI, provider);

          // Get pool data
          const [token0, token1, fee, slot0] = await Promise.all([
            poolContract.token0(),
            poolContract.token1(),
            poolContract.fee(),
            poolContract.slot0(),
          ]);

          const currentTick = Number(slot0.tick);
          const currentSqrtPriceX96 = slot0.sqrtPriceX96;

          // Get token contracts
          const token0Contract = new ethers.Contract(token0, ERC20_ABI, provider);
          const token1Contract = new ethers.Contract(token1, ERC20_ABI, provider);

          // Get token data
          const [token0Decimals, token1Decimals, token0Symbol, token1Symbol] = await Promise.all([
            token0Contract.decimals(),
            token1Contract.decimals(),
            token0Contract.symbol(),
            token1Contract.symbol(),
          ]);

          // For liquidity calculation, we need to provide desired amounts
          // Since we're analyzing existing positions, we'll use the current liquidity
          const result = this.uniswapMathService.calculateLiquidity({
            tickLower: Number(position.tickLower),
            tickUpper: Number(position.tickUpper),
            amount0Desired: BigInt(position.liquidity), // Using current liquidity as desired
            amount1Desired: BigInt(position.liquidity), // Using current liquidity as desired
            currentSqrtPriceX96: BigInt(currentSqrtPriceX96.toString()),
          });

          allPositions.push({
            tokenId: tokenId.toString(),
            poolAddress: poolAddress.toLowerCase(),
            liquidity: result.liquidity.toString(),
            amount0: result.amount0.toString(),
            amount1: result.amount1.toString(),
            amount0Human: Number(result.amount0) / Math.pow(10, Number(token0Decimals)),
            amount1Human: Number(result.amount1) / Math.pow(10, Number(token1Decimals)),
            token0Symbol,
            token1Symbol,
            token0Decimals,
            token1Decimals,
            currentTick,
            currentPrice: Math.pow(1.0001, currentTick),
          });

        } catch (error) {
          this.logger.warn(`Error processing position ${i}: ${error.message}`);
        }
      }

      if (allPositions.length === 0) {
        return {
          message: 'No positions found for this owner',
          positions: [],
        };
      }

      return this.convertBigIntToString({
        ownerAddress: dto.ownerAddress,
        network: dto.network,
        positions: allPositions,
      });

    } catch (error) {
      this.logger.error(`Error calculating liquidity: ${error.message}`);
      throw new Error(`Failed to calculate liquidity: ${error.message}`);
    }
  }
} 