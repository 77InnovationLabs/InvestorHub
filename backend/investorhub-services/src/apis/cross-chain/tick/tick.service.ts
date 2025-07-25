import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { ethers } from 'ethers';
import { NETWORKS_CONFIGS } from '../../shared/helpers/constants';
import { POOL_ABI } from '../../shared/ABIS/POOL';

const MIN_TICK = -887272;
const MAX_TICK = 887272;

@Injectable()
export class TickService {
  private readonly logger = new Logger(TickService.name);

  async getTickValues(network: string, poolAddress: string) {
    this.logger.log(`Getting tick values for pool ${poolAddress} on network ${network}`);

    const networkConfig = NETWORKS_CONFIGS[network];
    if (!networkConfig) {
      throw new BadRequestException(`Network ${network} is not supported`);
    }

    const provider = new ethers.providers.JsonRpcProvider(networkConfig.providerUrl);
    const poolContract = new ethers.Contract(poolAddress, POOL_ABI, provider);

    try {
      const tickSpacing = await poolContract.tickSpacing();
      const spacing = Number(tickSpacing);
      const minTick = Math.ceil(MIN_TICK / spacing) * spacing;
      const maxTick = Math.floor(MAX_TICK / spacing) * spacing;
      return {
        minTick,
        maxTick,
        tickSpacing: spacing,
      };
    } catch (error) {
      this.logger.error(`Error getting tick values: ${error.message}`);
      throw error;
    }
  }
}
