import { Controller, Post, Body, Logger, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBody } from '@nestjs/swagger';
import { QuoteService } from './quote.service';
import { GetBestUSDPriceQuoteRequestDto, GetBestTokenPriceQuoteRequestDto } from './dto/quote-request.dto';
import { USDPriceQuoteResponseDto, QuoteResponseDto } from './dto/quote-response.dto';
import { GetBestRouteRequestDto } from './dto/best-route-request.dto';
import { BestRouteResponseDto } from './dto/best-route-response.dto';

@ApiTags('Quote')
@Controller('quote')
export class QuoteController {
  private readonly logger = new Logger(QuoteController.name);

  constructor(private readonly quoteService: QuoteService) {}

  @Post('usd-price')
  @ApiOperation({
    summary: 'Get best USD price quote for a token',
    description: 'Returns the best USD price quote for a given token across all Uniswap V3 fee tiers (0.01%, 0.05%, 0.3%, 1%)'
  })
  @ApiBody({
    type: GetBestUSDPriceQuoteRequestDto,
    description: 'Token and network information for USD price quote'
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Best USD price quote retrieved successfully',
    type: USDPriceQuoteResponseDto
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: 'Invalid request parameters or unsupported network'
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: 'No valid quotes found for the token across all fee tiers'
  })
  async getBestUSDPriceQuote(
    @Body() request: GetBestUSDPriceQuoteRequestDto
  ): Promise<USDPriceQuoteResponseDto> {
    this.logger.log(`Received USD price quote request for token ${request.tokenSymbol} on network ${request.network}`);
    
    try {
      const result = await this.quoteService.getBestUSDPriceQuote(request);
      this.logger.log(`USD price quote successful: ${request.tokenSymbol} = $${result.quote} (fee: ${result.fee})`);
      return result;
    } catch (error) {
      this.logger.error(`USD price quote failed for ${request.tokenSymbol}: ${error.message}`);
      throw error;
    }
  }

  @Post('token-price')
  @ApiOperation({
    summary: 'Get best token price quote between two tokens',
    description: 'Returns the best price quote for swapping between two tokens across all Uniswap V3 fee tiers (0.01%, 0.05%, 0.3%, 1%)'
  })
  @ApiBody({
    type: GetBestTokenPriceQuoteRequestDto,
    description: 'Input and output token information for price quote'
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Best token price quote retrieved successfully',
    type: QuoteResponseDto
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: 'Invalid request parameters or unsupported network'
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: 'No valid quotes found for the token pair across all fee tiers'
  })
  async getBestTokenPriceQuote(
    @Body() request: GetBestTokenPriceQuoteRequestDto
  ): Promise<QuoteResponseDto> {
    this.logger.log(`Received token price quote request for ${request.tokenInSymbol} → ${request.tokenOutSymbol} on network ${request.network}`);
    
    try {
      const result = await this.quoteService.getBestTokenPriceQuote(request);
      this.logger.log(`Token price quote successful: ${request.tokenInSymbol} → ${request.tokenOutSymbol} = ${result.quote} (fee: ${result.fee})`);
      return result;
    } catch (error) {
      this.logger.error(`Token price quote failed for ${request.tokenInSymbol} → ${request.tokenOutSymbol}: ${error.message}`);
      throw error;
    }
  }

  @Post('best-route')
  @ApiOperation({
    summary: 'Get best route for swapping between tokens',
    description: 'Returns the best route for swapping between two tokens using Uniswap Smart Order Router, including multi-hop routes and gas estimates'
  })
  @ApiBody({
    type: GetBestRouteRequestDto,
    description: 'Token and swap parameters for finding the best route'
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: 'Best route found successfully',
    type: BestRouteResponseDto
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: 'Invalid request parameters or unsupported network'
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: 'No route found for the token pair'
  })
  async getBestRoute(
    @Body() request: GetBestRouteRequestDto
  ): Promise<BestRouteResponseDto> {
    this.logger.log(`Received best route request for ${request.tokenInSymbol} → ${request.tokenOutSymbol} on network ${request.network}`);
    
    try {
      const result = await this.quoteService.getBestRoute(request);
      this.logger.log(`Best route found: ${request.tokenInSymbol} → ${request.tokenOutSymbol}, output: ${result.amountOut}, gas: ${result.gasCost}`);
      return result;
    } catch (error) {
      this.logger.error(`Best route failed for ${request.tokenInSymbol} → ${request.tokenOutSymbol}: ${error.message}`);
      throw error;
    }
  }
}
