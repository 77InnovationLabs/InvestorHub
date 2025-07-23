import { ApiProperty } from '@nestjs/swagger';

export class RouteHopDto {
  @ApiProperty({ 
    example: '0x779877A7B0D9E8603169DdbD7836e478b4624789', 
    description: 'Token address for this hop' 
  })
  tokenIn: string;

  @ApiProperty({ 
    example: 'LINK', 
    description: 'Token symbol for this hop' 
  })
  tokenInSymbol: string;

  @ApiProperty({ 
    example: '0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14', 
    description: 'Next token address in the route' 
  })
  tokenOut: string;

  @ApiProperty({ 
    example: 'WETH', 
    description: 'Next token symbol in the route' 
  })
  tokenOutSymbol: string;

  @ApiProperty({ 
    example: 3000, 
    description: 'Fee tier for this hop' 
  })
  fee: number;

  @ApiProperty({ 
    example: '0x1234567890abcdef...', 
    description: 'Pool address for this hop' 
  })
  poolAddress: string;
}

export class BestRouteResponseDto {
  @ApiProperty({ 
    example: '1000000000000000000', 
    description: 'Input amount in wei' 
  })
  amountIn: string;

  @ApiProperty({ 
    example: '999500000000000000', 
    description: 'Expected output amount in wei' 
  })
  amountOut: string;

  @ApiProperty({ 
    example: '500000', 
    description: 'Estimated gas cost in wei' 
  })
  gasCost: string;

  @ApiProperty({ 
    example: '0x779877A7B0D9E8603169DdbD7836e478b4624789', 
    description: 'Input token address' 
  })
  tokenInAddress: string;

  @ApiProperty({ 
    example: 'LINK', 
    description: 'Input token symbol' 
  })
  tokenInSymbol: string;

  @ApiProperty({ 
    example: '0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14', 
    description: 'Output token address' 
  })
  tokenOutAddress: string;

  @ApiProperty({ 
    example: 'WETH', 
    description: 'Output token symbol' 
  })
  tokenOutSymbol: string;

  @ApiProperty({ 
    example: 'eip155:11155111', 
    description: 'Network where the route was found' 
  })
  network: string;

  @ApiProperty({ 
    example: 'EXACT_INPUT', 
    description: 'Trade type' 
  })
  tradeType: string;

  @ApiProperty({ 
    type: [RouteHopDto], 
    description: 'Array of hops in the route' 
  })
  route: RouteHopDto[];

  @ApiProperty({ 
    example: '2024-01-15T10:30:00.000Z', 
    description: 'Timestamp when the route was generated' 
  })
  timestamp: string;

  @ApiProperty({ 
    example: '0x1234567890abcdef...', 
    description: 'Method parameters for executing the swap' 
  })
  methodParameters?: {
    calldata: string;
    value: string;
    to: string;
  };
  @ApiProperty({ 
    example: '', 
    description: 'Best route response itself' 
  })
  bestRoute: any;
} 