import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsUrl, IsNumber } from 'class-validator';

export class CreateNetworkConfigDto {
  @ApiProperty({ description: 'Network name', example: 'Ethereum Mainnet' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ description: 'GraphQL URL for the network', example: 'https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v3' })
  @IsString()
  @IsNotEmpty()
  @IsUrl()
  graphqlUrl: string;
}

export class UpdateNetworkConfigDto extends CreateNetworkConfigDto {}

export class NetworkConfigResponseDto extends CreateNetworkConfigDto {
  @ApiProperty({ description: 'Network configuration ID' })
  id: string;

  @ApiProperty({ description: 'Chain ID for the network', example: 1 })
  @IsNumber()
  chainId: number;
} 