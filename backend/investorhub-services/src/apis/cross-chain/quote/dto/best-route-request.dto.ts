import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsEthereumAddress, IsNumber, Min, Max, IsOptional } from 'class-validator';

export class GetBestRouteRequestDto {
  @ApiProperty({ 
    example: 'eip155:11155111', 
    description: 'Network chain ID (e.g., eip155:11155111 for Sepolia, eip155:84532 for Base Sepolia)' 
  })
  @IsString()
  network: string;

  @ApiProperty({ 
    example: '0x779877A7B0D9E8603169DdbD7836e478b4624789', 
    description: 'Input token contract address' 
  })
  @IsEthereumAddress()
  tokenInAddress: string;

  @ApiProperty({ 
    example: 18, 
    description: 'Input token decimals', 
    minimum: 0, 
    maximum: 255 
  })
  @IsNumber()
  @Min(0)
  @Max(255)
  tokenInDecimals: number;

  @ApiProperty({ 
    example: 'LINK', 
    description: 'Input token symbol' 
  })
  @IsString()
  tokenInSymbol: string;

  @ApiProperty({ 
    example: '0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14', 
    description: 'Output token contract address' 
  })
  @IsEthereumAddress()
  tokenOutAddress: string;

  @ApiProperty({ 
    example: 18, 
    description: 'Output token decimals', 
    minimum: 0, 
    maximum: 255 
  })
  @IsNumber()
  @Min(0)
  @Max(255)
  tokenOutDecimals: number;

  @ApiProperty({ 
    example: 'WETH', 
    description: 'Output token symbol' 
  })
  @IsString()
  tokenOutSymbol: string;

  @ApiProperty({ 
    example: '1000000000000000000', 
    description: 'Amount to swap in wei (raw amount)', 
    required: false 
  })
  @IsOptional()
  @IsString()
  amountIn?: string;

  @ApiProperty({ 
    example: '1000000000000000000', 
    description: 'Amount to receive in wei (raw amount) - for exact output swaps', 
    required: false 
  })
  @IsOptional()
  @IsString()
  amountOut?: string;

  @ApiProperty({ 
    example: 'EXACT_INPUT', 
    description: 'Trade type: EXACT_INPUT or EXACT_OUTPUT', 
    enum: ['EXACT_INPUT', 'EXACT_OUTPUT'],
    default: 'EXACT_INPUT'
  })
  @IsOptional()
  @IsString()
  tradeType?: 'EXACT_INPUT' | 'EXACT_OUTPUT';

  @ApiProperty({ 
    example: '0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6', 
    description: 'Recipient address for the swap', 
    required: false 
  })
  @IsOptional()
  @IsEthereumAddress()
  recipient?: string;

  @ApiProperty({ 
    example: 50, 
    description: 'Slippage tolerance in basis points (e.g., 50 = 0.5%)', 
    minimum: 0, 
    maximum: 10000,
    default: 50
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(10000)
  slippageTolerance?: number;
} 