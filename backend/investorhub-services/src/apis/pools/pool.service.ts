import {
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { PoolRepository } from './repositories/pool.repository';
import { PoolDayDataRepository } from './repositories/pool-day-data.repository';
import { UniswapPoolResponseDto, UniswapPoolsResponseDto } from '../shared/dtos/list-pools-response.dto';
import { Pool } from '../../database/schemas/pool.schemas';
import { PoolDayData } from '../../database/schemas/pool-day-data.schema';

@Injectable()
export class PoolService {
  private readonly logger = new Logger(PoolService.name);

  constructor(
    private readonly poolRepository: PoolRepository,
    private readonly poolDayDataRepository: PoolDayDataRepository,
  ) { }

  private calculatePoolMetrics(pool: Pool, poolDayData: PoolDayData[]): UniswapPoolResponseDto {
    // Calculate APR24h for each day's data
    const poolDayDataWithApr = poolDayData.map(dayData => {
      const dayFees = parseFloat(dayData.feesUSD) || 0;
      const dayTVL = parseFloat(dayData.tvlUSD) || 0;

      let apr24h = 0;
      if (dayTVL > 0) {
        apr24h = (dayFees / dayTVL) * 365 * 100;
      }

      return {
        date: dayData.date,
        feesUSD: dayData.feesUSD,
        volumeUSD: dayData.volumeUSD,
        tvlUSD: dayData.tvlUSD,
        apr24h: apr24h.toFixed(2),
      };
    });

    // Type guard to ensure tokens are populated
    const token0 = typeof pool.token0 === 'object' && pool.token0 !== null && 'name' in pool.token0 
      ? pool.token0 as any 
      : { id: pool.token0.toString(), name: '', symbol: '', address: '', decimals: '0', network: { id: '', name: '', graphqlUrl: '' } };
    
    const token1 = typeof pool.token1 === 'object' && pool.token1 !== null && 'name' in pool.token1 
      ? pool.token1 as any 
      : { id: pool.token1.toString(), name: '', symbol: '', address: '', decimals: '0', network: { id: '', name: '', graphqlUrl: '' } };
    
    return {
      _id: pool._id.toString(),
      feeTier: pool.feeTier,
      address: pool.address,
      token0: {
        id: token0._id.toString(),
        name: token0.name,
        symbol: token0.symbol,
        address: token0.address,
        decimals: token0.decimals || '0',
        network: {
          id: token0.network?._id?.toString() || '',
          name: token0.network?.name || '',
          graphqlUrl: token0.network?.graphqlUrl || '',
        },
      },
      token1: {
        id: token1._id.toString(),
        name: token1.name,
        symbol: token1.symbol,
        address: token1.address,
        decimals: token1.decimals || '0',
        network: {
          id: token1.network?._id?.toString() || '',
          name: token1.network?.name || '',
          graphqlUrl: token1.network?.graphqlUrl || '',
        },
      },
      createdAtTimestamp: pool.block || '0',
      poolDayData: poolDayDataWithApr,
    };
  }

  async fetchPoolsForTokenPair(token0Address: string, token1Address: string): Promise<UniswapPoolsResponseDto> {
    try {
      // Find pools for this token pair
      const pools = await this.poolRepository.findByTokenAddresses(token0Address, token1Address);
      
      if (!pools || pools.length === 0) {
        throw new NotFoundException(`No pools found for token pair: ${token0Address}, ${token1Address}`);
      }
      
      const poolIds = pools.map(pool => pool._id.toString());
      
      // Get pool day data for all pools
      const allPoolDayData = await this.poolDayDataRepository.findByPoolIds(poolIds);

      // Group pool day data by pool ID
      const poolDayDataByPoolId = allPoolDayData.reduce((acc, data) => {
        const poolId = data.id_pool.toString();
        if (!acc[poolId]) {
          acc[poolId] = [];
        }
        acc[poolId].push(data);
        return acc;
      }, {});

      // Transform pools with day data
      const transformedPools = pools.map(pool => {
        const poolId = pool._id.toString();
        const dayData = poolDayDataByPoolId[poolId] || [];
        return this.calculatePoolMetrics(pool, dayData);
      });

      const responseDto: UniswapPoolsResponseDto = {
        pools: transformedPools,
        blockNumber: '0', // MongoDB doesn't have block numbers, so we set to 0
      };

      return responseDto;
    } catch (error) {
      this.logger.error(`Error fetching pools for token pair ${token0Address}, ${token1Address}:`, error);

      if (error instanceof NotFoundException) {
        throw error;
      }

      throw new ServiceUnavailableException('Service temporarily unavailable');
    }
  }

  async fetchAllPools(): Promise<UniswapPoolsResponseDto> {
    try {
      // Get all pools
      const pools = await this.poolRepository.findAll();
      
      if (!pools || pools.length === 0) {
        throw new NotFoundException('No pools found');
      }

      // Get all pool day data
      const poolIds = pools.map(pool => pool._id.toString());
      const allPoolDayData = await this.poolDayDataRepository.findByPoolIds(poolIds);
      
      // Group pool day data by pool ID
      const poolDayDataByPoolId = allPoolDayData.reduce((acc, data) => {
        const poolId = data.id_pool.toString();
        if (!acc[poolId]) {
          acc[poolId] = [];
        }
        acc[poolId].push(data);
        return acc;
      }, {});
      
      // Transform pools with day data
      const transformedPools = pools.map(pool => {
        const poolId = pool._id.toString();
        const dayData = poolDayDataByPoolId[poolId] || [];
        return this.calculatePoolMetrics(pool, dayData);
      });
      
      const responseDto: UniswapPoolsResponseDto = {
        pools: transformedPools,
        blockNumber: '0', // MongoDB doesn't have block numbers, so we set to 0
      };
      
      return responseDto;
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      this.logger.error(`Error fetching all pools: ${error.message}`, error.stack);
      throw new ServiceUnavailableException('Service temporarily unavailable');
    }
  }

  async fetchPoolById(poolId: string): Promise<UniswapPoolResponseDto> {
    try {
      this.logger.log(`Fetching pool with ID: ${poolId}`);
      
      // Validate pool ID format
      if (!poolId || poolId.length !== 24) {
        throw new NotFoundException(`Invalid pool ID format: ${poolId}`);
      }

      // Find the specific pool
      const pool = await this.poolRepository.findById(poolId);
      
      if (!pool) {
        this.logger.warn(`Pool not found with ID: ${poolId}`);
        throw new NotFoundException(`Pool with ID ${poolId} not found`);
      }

      this.logger.debug(`Found pool: ${poolId}, feeTier: ${pool.feeTier}, address: ${pool.address}`);

      // Get pool day data for this specific pool
      const poolDayData = await this.poolDayDataRepository.findByPoolIds([poolId]);
      
      this.logger.debug(`Found ${poolDayData.length} day data entries for pool: ${poolId}`);
      
      // Transform pool with day data
      const transformedPool = this.calculatePoolMetrics(pool, poolDayData);
      
      this.logger.log(`Successfully transformed pool: ${poolId}`);
      return transformedPool;
    } catch (error) {
      this.logger.error(`Error fetching pool with ID ${poolId}: ${error.message}`, error.stack);
      
      if (error instanceof NotFoundException) {
        throw error;
      }
      
      throw new ServiceUnavailableException('Service temporarily unavailable');
    }
  }
} 