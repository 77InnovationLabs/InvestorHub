import { Injectable, Logger, BadRequestException, NotFoundException } from '@nestjs/common';
import { ethers } from 'ethers';
import { ethers as ethersv6 } from 'ethersV6'
import { AlphaRouter, MixedRoute, SwapType } from '@uniswap/smart-order-router';
import { CurrencyAmount, Token, TradeType, Percent } from '@uniswap/sdk-core';
import { NETWORKS_CONFIGS, ALL_FEE_TIERS } from '../../shared/helpers/constants';
import { QUOTER_ABI } from '../../shared/ABIS/QUOTER';
import { fromReadableAmount, toReadableAmount } from '../../shared/utils/amount-conversions';
import { GetBestUSDPriceQuoteRequestDto, GetBestTokenPriceQuoteRequestDto } from './dto/quote-request.dto';
import { USDPriceQuoteResponseDto, QuoteResponseDto } from './dto/quote-response.dto';
import { GetBestRouteRequestDto } from './dto/best-route-request.dto';
import { BestRouteResponseDto, RouteHopDto } from './dto/best-route-response.dto';

@Injectable()
export class QuoteService {
  private readonly logger = new Logger(QuoteService.name);
  private readonly AMOUNT_1 = 1;

  /**
   * Get the best USD price quote for a token across all fee tiers
   */
  async getBestUSDPriceQuote(request: GetBestUSDPriceQuoteRequestDto): Promise<USDPriceQuoteResponseDto> {
    this.logger.log(`Getting best USD price quote for token ${request.tokenSymbol} on network ${request.network}`);

    // Validate network exists
    const networkConfig = NETWORKS_CONFIGS[request.network];
    if (!networkConfig) {
      throw new BadRequestException(`Network ${request.network} is not supported`);
    }

    // Check if token is already USD token
    if (request.tokenAddress.toLowerCase() === networkConfig.usdToken.address.toLowerCase()) {
      this.logger.log(`Token ${request.tokenSymbol} is USD token, returning 1:1 quote`);
      return {
        quote: '1',
        fee: 0,
        tokenAddress: request.tokenAddress,
        tokenSymbol: request.tokenSymbol,
        network: request.network,
        timestamp: new Date().toISOString()
      };
    }

    // Create provider and contract
    const provider = new ethersv6.JsonRpcProvider(networkConfig.providerUrl);
    const quoterContract = new ethersv6.Contract(
      networkConfig.quoterContract,
      QUOTER_ABI,
      provider
    );

    const usdToken = networkConfig.usdToken;
    const amountIn = fromReadableAmount(
      this.AMOUNT_1,
      request.tokenDecimals
    ).toString();

    this.logger.log(`Trying all fee tiers for token ${request.tokenSymbol} to USD`);

    let bestQuote: string | null = null;
    let bestFee = 0;
    let hasValidQuote = false;

    for (const fee of ALL_FEE_TIERS) {
      try {
        this.logger.debug(`Trying fee tier: ${fee}`);
        
        const path = ethersv6.solidityPacked(
          ['address', 'uint24', 'address'],
          [request.tokenAddress, BigInt(fee), usdToken.address]
        );

        const quotedAmountOut = await quoterContract.quoteExactInput.staticCall(
          path,
          amountIn
        );

        const readableQuote = toReadableAmount(quotedAmountOut[0], usdToken.decimals);
        this.logger.debug(`Fee ${fee}: quote = ${readableQuote}`);

        if (!bestQuote || Number(readableQuote) > Number(bestQuote)) {
          bestQuote = readableQuote;
          bestFee = fee;
          hasValidQuote = true;
        }
      } catch (error) {
        this.logger.debug(`Fee tier ${fee} failed: ${error.message}`);
        // Continue to next fee tier
      }
    }

    if (!hasValidQuote) {
      throw new NotFoundException(`No valid quotes found for token ${request.tokenSymbol} to USD across all fee tiers`);
    }

    this.logger.log(`Best quote: ${bestQuote} at fee tier ${bestFee}`);
    
    return {
      quote: bestQuote!,
      fee: bestFee,
      tokenAddress: request.tokenAddress,
      tokenSymbol: request.tokenSymbol,
      network: request.network,
      timestamp: new Date().toISOString()
    };
  }

  /**
   * Get the best token price quote between two tokens across all fee tiers
   */
  async getBestTokenPriceQuote(request: GetBestTokenPriceQuoteRequestDto): Promise<QuoteResponseDto> {
    this.logger.log(`Getting best token price quote for ${request.tokenInSymbol} → ${request.tokenOutSymbol} on network ${request.network}`);

    // Validate network exists
    const networkConfig = NETWORKS_CONFIGS[request.network];
    if (!networkConfig) {
      throw new BadRequestException(`Network ${request.network} is not supported`);
    }

    // Create provider and contract
    const provider = new ethersv6.JsonRpcProvider(networkConfig.providerUrl);
    const quoterContract = new ethersv6.Contract(
      networkConfig.quoterContract,
      QUOTER_ABI,
      provider
    );

    const amountIn = fromReadableAmount(
      this.AMOUNT_1,
      request.tokenInDecimals
    ).toString();

    this.logger.log(`Trying all fee tiers for ${request.tokenInSymbol} → ${request.tokenOutSymbol}`);

    let bestQuote: string | null = null;
    let bestFee = 0;
    let hasValidQuote = false;

    for (const fee of ALL_FEE_TIERS) {
      try {
        this.logger.debug(`Trying fee tier: ${fee}`);
        
        const path = ethersv6.solidityPacked(
          ['address', 'uint24', 'address'],
          [request.tokenInAddress, BigInt(fee), request.tokenOutAddress]
        );

        const quotedAmountOut = await quoterContract.quoteExactInput.staticCall(
          path,
          amountIn
        );

        const readableQuote = toReadableAmount(quotedAmountOut[0], request.tokenOutDecimals);
        this.logger.debug(`Fee ${fee}: quote = ${readableQuote}`);

        if (!bestQuote || Number(readableQuote) > Number(bestQuote)) {
          bestQuote = readableQuote;
          bestFee = fee;
          hasValidQuote = true;
        }
      } catch (error) {
        this.logger.debug(`Fee tier ${fee} failed: ${error.message}`);
        // Continue to next fee tier
      }
    }

    if (!hasValidQuote) {
      throw new NotFoundException(`No valid quotes found for ${request.tokenInSymbol} to ${request.tokenOutSymbol} across all fee tiers`);
    }

    this.logger.log(`Best quote: ${bestQuote} at fee tier ${bestFee}`);
    
    return {
      quote: bestQuote!,
      fee: bestFee,
      tokenInAddress: request.tokenInAddress,
      tokenInSymbol: request.tokenInSymbol,
      tokenOutAddress: request.tokenOutAddress,
      tokenOutSymbol: request.tokenOutSymbol,
      network: request.network,
      timestamp: new Date().toISOString()
    };
  }

  /**
   * Get the best route for swapping between two tokens using Uniswap Smart Order Router
   */
  async getBestRoute(request: GetBestRouteRequestDto): Promise<BestRouteResponseDto> {
    this.logger.log(`Getting best route for ${request.tokenInSymbol} → ${request.tokenOutSymbol} on network ${request.network}`);

    // Validate network exists
    const networkConfig = NETWORKS_CONFIGS[request.network];
    if (!networkConfig) {
      throw new BadRequestException(`Network ${request.network} is not supported`);
    }

    // Get chain ID from network string
    const chainId = parseInt(request.network.replace('eip155:', ''));
    
    // Create provider
    const provider = new ethers.providers.JsonRpcProvider(networkConfig.providerUrl);

    // Create tokens
    const tokenIn = new Token(
      chainId,
      request.tokenInAddress,
      request.tokenInDecimals,
      request.tokenInSymbol
    );

    const tokenOut = new Token(
      chainId,
      request.tokenOutAddress,
      request.tokenOutDecimals,
      request.tokenOutSymbol
    );

    // Set default values
    const tradeType = request.tradeType || 'EXACT_INPUT';
    const slippageTolerance = request.slippageTolerance || 50; // 0.5%
    const recipient = request.recipient || '0x0000000000000000000000000000000000000000';

    // Determine amount
    let amount: CurrencyAmount<Token>;
    if (tradeType === 'EXACT_INPUT') {
      if (!request.amountIn) {
        throw new BadRequestException('amountIn is required for EXACT_INPUT trades');
      }
      amount = CurrencyAmount.fromRawAmount(tokenIn, request.amountIn);
    } else {
      if (!request.amountOut) {
        throw new BadRequestException('amountOut is required for EXACT_OUTPUT trades');
      }
      amount = CurrencyAmount.fromRawAmount(tokenOut, request.amountOut);
    }

    try {
      // Create Alpha Router
      const router = new AlphaRouter({
        chainId,
        provider: provider as any,
      });

      this.logger.log(`Finding best route for ${amount.toSignificant(6)} ${tokenIn.symbol} → ${tokenOut.symbol}`);

      // Get best route from AlphaRouter
      const bestRoute = await router.route(
        amount,
        tradeType === 'EXACT_INPUT' ? tokenOut : tokenIn,
        tradeType === 'EXACT_INPUT' ? TradeType.EXACT_INPUT : TradeType.EXACT_OUTPUT,
        {
          type: SwapType.SWAP_ROUTER_02,
          recipient: recipient as string,
          slippageTolerance: new Percent(slippageTolerance, 10_000),
          deadline: Math.floor(Date.now() / 1000) + 900, // 15 minutes
        }
      );

      if (!bestRoute) {
        throw new NotFoundException(`No route found for ${request.tokenInSymbol} → ${request.tokenOutSymbol}`);
      }

      this.logger.log(`Route found, expected output: ${bestRoute.quote.toExact()} ${tokenOut.symbol}`);
      
      // Extract route information from the actual route object
      const routeHops: RouteHopDto[] = [];
      
      // The route object is an array where each element contains route information
      const routeData = bestRoute as any;
      
      if (routeData.route && Array.isArray(routeData.route) && routeData.route.length > 0) {
        // Process each route segment
        for (let routeIndex = 0; routeIndex < routeData.route.length; routeIndex++) {
          const routeSegment = routeData.route[routeIndex];
          const mixedRoute = routeSegment.route as MixedRoute;
          
          if (mixedRoute && mixedRoute.pools && mixedRoute.pools.length > 0) {
            this.logger.debug(`Processing route segment ${routeIndex + 1} with ${mixedRoute.pools.length} pools`);
            
            // Extract pools and token path from this route segment
            const pools = mixedRoute.pools;
            const tokenPath = routeSegment.tokenPath;
            
            this.logger.debug(`Token path length: ${tokenPath?.length || 0}`);
            
            // Create route hops from pools and token path
            for (let i = 0; i < pools.length; i++) {
              const pool = pools[i];
              const tokenIn = tokenPath[i];
              const tokenOut = tokenPath[i + 1];
              
              // Use type assertion to access pool properties
              const poolAny = pool as any;
              
              this.logger.debug(`Processing hop ${i}: tokenIn=${tokenIn?.symbol}, tokenOut=${tokenOut?.symbol}, pool.fee=${poolAny?.fee}`);
              
              if (tokenIn && tokenOut && pool) {
                routeHops.push({
                  tokenIn: tokenIn.address,
                  tokenInSymbol: tokenIn.symbol,
                  tokenOut: tokenOut.address,
                  tokenOutSymbol: tokenOut.symbol,
                  fee: poolAny.fee || 3000, // Default to 3000 if fee not available
                  poolAddress: routeData.poolIdentifiers?.[routeHops.length] || '0x0000000000000000000000000000000000000000',
                });
                
                this.logger.debug(`Route hop ${routeHops.length}: ${tokenIn.symbol} -> ${tokenOut.symbol} (fee: ${poolAny.fee}, pool: ${routeData.poolIdentifiers?.[routeHops.length - 1]})`);
              } else {
                this.logger.warn(`Skipping hop ${i}: missing data - tokenIn: ${!!tokenIn}, tokenOut: ${!!tokenOut}, pool: ${!!pool}`);
              }
            }
          } else {
            this.logger.warn(`Route segment ${routeIndex + 1} has no pools or invalid structure`);
          }
        }
      } else {
        this.logger.warn('Route structure not found or route array is empty');
        this.logger.debug(`routeData.route exists: ${!!routeData.route}`);
        this.logger.debug(`routeData.route is array: ${Array.isArray(routeData.route)}`);
        this.logger.debug(`routeData.route length: ${routeData.route?.length || 0}`);
      }
      
      // If no route hops were extracted, create a fallback using input/output tokens
      if (routeHops.length === 0) {
        this.logger.warn('No route hops could be extracted, using fallback');
        const inputToken = routeData.route?.input || routeData.amount?.currency;
        const outputToken = routeData.route?.output || routeData.quote?.currency;
        
        routeHops.push({
          tokenIn: inputToken?.address || request.tokenInAddress,
          tokenInSymbol: inputToken?.symbol || request.tokenInSymbol,
          tokenOut: outputToken?.address || request.tokenOutAddress,
          tokenOutSymbol: outputToken?.symbol || request.tokenOutSymbol,
          fee: 3000,
          poolAddress: routeData.poolIdentifiers?.[0] || '0x0000000000000000000000000000000000000000',
        });
      }

      return {
        amountIn: amount.quotient.toString(),
        amountOut: bestRoute.quote.toExact(),
        gasCost: routeData.gasEstimate?.hex ? 
          ethers.BigNumber.from(routeData.gasEstimate.hex).toString() : 
          bestRoute.estimatedGasUsed.toString(),
        tokenInAddress: request.tokenInAddress,
        tokenInSymbol: request.tokenInSymbol,
        tokenOutAddress: request.tokenOutAddress,
        tokenOutSymbol: request.tokenOutSymbol,
        network: request.network,
        tradeType,
        route: routeHops,
        timestamp: new Date().toISOString(),
        methodParameters: bestRoute.methodParameters ? {
          calldata: bestRoute.methodParameters.calldata,
          value: bestRoute.methodParameters.value,
          to: bestRoute.methodParameters.to,
        } : undefined,
        bestRoute,
      };

    } catch (error) {
      this.logger.error(`Error finding route: ${error.message}`);
      throw new NotFoundException(`Failed to find route for ${request.tokenInSymbol} → ${request.tokenOutSymbol}: ${error.message}`);
    }
  }
}
