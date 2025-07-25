import { Controller, Post, Body, Logger, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBody } from '@nestjs/swagger';
import { TickService } from './tick.service';
import { GetTickValuesRequestDto } from './dto/tick-request.dto';
import { TickValuesResponseDto } from './dto/tick-response.dto';

@ApiTags('Tick')
@Controller('tick')
export class TickController {
  private readonly logger = new Logger(TickController.name);

  constructor(private readonly tickService: TickService) {}

  @Post('tick-values')
  @ApiOperation({
    summary: 'Get min/max tick values and tick spacing for a Uniswap V3 pool',
    description: 'Returns the minTick, maxTick, and tickSpacing for a given Uniswap V3 pool address and network.'
  })
  @ApiBody({
    type: GetTickValuesRequestDto,
    description: 'Pool address and network chain ID.'
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Tick values retrieved successfully',
    type: TickValuesResponseDto
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: 'Invalid request parameters or unsupported network'
  })
  async getTickValues(
    @Body() request: GetTickValuesRequestDto
  ): Promise<TickValuesResponseDto> {
    this.logger.log(`Received tick values request for pool ${request.poolAddress} on network ${request.network}`);
    try {
      const result = await this.tickService.getTickValues(request.network, request.poolAddress);
      this.logger.log(`Tick values: minTick=${result.minTick}, maxTick=${result.maxTick}, spacing=${result.tickSpacing}`);
      return result;
    } catch (error) {
      this.logger.error(`Tick values failed for pool ${request.poolAddress}: ${error.message}`);
      throw error;
    }
  }
}
