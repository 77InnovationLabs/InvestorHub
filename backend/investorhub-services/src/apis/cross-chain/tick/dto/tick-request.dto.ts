import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsEthereumAddress } from 'class-validator';

export class GetTickValuesRequestDto {
  @ApiProperty({
    example: 'eip155:11155111',
    description: 'Network chain ID (e.g., eip155:11155111 for Sepolia, eip155:84532 for Base Sepolia)'
  })
  @IsString()
  network: string;

  @ApiProperty({
    example: '0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8',
    description: 'Uniswap V3 Pool contract address'
  })
  @IsEthereumAddress()
  poolAddress: string;
} 