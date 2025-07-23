import { ApiProperty } from '@nestjs/swagger';

export class QuoteResponseDto {
  @ApiProperty({ 
    example: '1.23456789', 
    description: 'Best quote amount received for 1 unit of input token' 
  })
  quote: string;

  @ApiProperty({ 
    example: 3000, 
    description: 'Fee tier that provided the best quote (100, 500, 3000, or 10000)' 
  })
  fee: number;

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
    description: 'Network where the quote was obtained' 
  })
  network: string;

  @ApiProperty({ 
    example: '2024-01-15T10:30:00.000Z', 
    description: 'Timestamp when the quote was generated' 
  })
  timestamp: string;
}

export class USDPriceQuoteResponseDto {
  @ApiProperty({ 
    example: '1.23456789', 
    description: 'Best USD price quote for 1 unit of input token' 
  })
  quote: string;

  @ApiProperty({ 
    example: 3000, 
    description: 'Fee tier that provided the best quote (100, 500, 3000, or 10000)' 
  })
  fee: number;

  @ApiProperty({ 
    example: '0x779877A7B0D9E8603169DdbD7836e478b4624789', 
    description: 'Token address' 
  })
  tokenAddress: string;

  @ApiProperty({ 
    example: 'LINK', 
    description: 'Token symbol' 
  })
  tokenSymbol: string;

  @ApiProperty({ 
    example: 'eip155:11155111', 
    description: 'Network where the quote was obtained' 
  })
  network: string;

  @ApiProperty({ 
    example: '2024-01-15T10:30:00.000Z', 
    description: 'Timestamp when the quote was generated' 
  })
  timestamp: string;
} 