import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsEthereumAddress, IsNumber, IsOptional, Min, Max } from 'class-validator';

export class GetBestUSDPriceQuoteRequestDto {
  @ApiProperty({ 
    example: 'eip155:11155111', 
    description: 'Network chain ID (e.g., eip155:11155111 for Sepolia, eip155:84532 for Base Sepolia)' 
  })
  @IsString()
  network: string;

  @ApiProperty({ 
    example: '0x779877A7B0D9E8603169DdbD7836e478b4624789', 
    description: 'Token contract address to get USD price for' 
  })
  @IsEthereumAddress()
  tokenAddress: string;

  @ApiProperty({ 
    example: 18, 
    description: 'Token decimals (e.g., 18 for ETH, 6 for USDC)', 
    minimum: 0, 
    maximum: 255 
  })
  @IsNumber()
  @Min(0)
  @Max(255)
  tokenDecimals: number;

  @ApiProperty({ 
    example: 'LINK', 
    description: 'Token symbol for logging purposes' 
  })
  @IsString()
  tokenSymbol: string;
}

export class GetBestTokenPriceQuoteRequestDto {
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
} 