import { Controller, Post, Body, Get, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiParam } from '@nestjs/swagger';
import { PoolService } from './pool.service';
import { ListPoolsRequestDto } from '../shared/dtos/list-pools-request.dto';
import { UniswapPoolResponseDto, UniswapPoolsResponseDto } from '../shared/dtos/list-pools-response.dto';
import { ErrorResponseDto } from '../shared/dtos/error-response.dto';

@ApiTags('Pools')
@Controller('pools')
export class PoolController {
  constructor(private readonly poolService: PoolService) {}

  @Post()
  @ApiOperation({ summary: 'Get pools for token pair from MongoDB' })
  @ApiResponse({ status: 200, description: 'Pools retrieved successfully', type: UniswapPoolsResponseDto })
  @ApiResponse({ status: 400, description: 'Invalid token addresses', type: ErrorResponseDto })
  @ApiResponse({ status: 404, description: 'No pools found for the given token pair', type: ErrorResponseDto })
  @ApiResponse({ status: 503, description: 'Service temporarily unavailable', type: ErrorResponseDto })
  async getPools(@Body() body: ListPoolsRequestDto): Promise<UniswapPoolsResponseDto> {
    const { token0, token1 } = body;
    return this.poolService.fetchPoolsForTokenPair(token0, token1);
  }

  @Get()
  @ApiOperation({ summary: 'Get all pools from MongoDB' })
  @ApiResponse({ status: 200, description: 'All pools retrieved successfully', type: UniswapPoolsResponseDto })
  @ApiResponse({ status: 404, description: 'No pools found', type: ErrorResponseDto })
  @ApiResponse({ status: 503, description: 'Service temporarily unavailable', type: ErrorResponseDto })
  async getAllPools(): Promise<UniswapPoolsResponseDto> {
    return this.poolService.fetchAllPools();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get pool by ID from MongoDB' })
  @ApiParam({ name: 'id', description: 'Pool ID', example: '507f1f77bcf86cd799439011' })
  @ApiResponse({ status: 200, description: 'Pool retrieved successfully', type: UniswapPoolResponseDto })
  @ApiResponse({ status: 404, description: 'Pool not found', type: ErrorResponseDto })
  @ApiResponse({ status: 503, description: 'Service temporarily unavailable', type: ErrorResponseDto })
  async getPoolById(@Param('id') id: string): Promise<UniswapPoolResponseDto> {
    return this.poolService.fetchPoolById(id);
  }
} 