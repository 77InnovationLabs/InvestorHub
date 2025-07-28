import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsNumberString,
  IsObject,
  IsString,
  ValidateNested,
} from 'class-validator';
import { PoolDayDataDto } from './pool-day-data.dto';
import { NetworkConfigResponseDto } from '../../network-config/dto/network-config.dto';

class TokenInfoDto {
  @ApiProperty({ example: '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48' })
  @IsString()
  id: string;

  @ApiProperty({ example: 'USD Coin' })
  @IsString()
  name: string;

  @ApiProperty({ example: 'USDC' })
  @IsString()
  symbol: string;

  @ApiProperty({ example: '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48' })
  @IsString()
  address: string;

  @ApiProperty({ example: 6, description: 'Number of decimal places for the token' })
  @IsNumberString()
  decimals: string;

  @ApiProperty({ type: NetworkConfigResponseDto })
  @ValidateNested()
  @Type(() => NetworkConfigResponseDto)
  @IsObject()
  network: NetworkConfigResponseDto;
}

export class UniswapPoolResponseDto {
  @ApiProperty({ example: '507f1f77bcf86cd799439011', description: 'Pool ID' })
  @IsString()
  _id: string;

  @ApiProperty({ example: '3000', description: 'Fee tier in hundredths of a bip, e.g., 3000 = 0.3%' })
  @IsNumberString()
  feeTier: string;

  @ApiProperty({ example: '0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8', description: 'Pool address' })
  @IsString()
  address: string;

  @ApiProperty({ type: TokenInfoDto })
  @ValidateNested()
  @Type(() => TokenInfoDto)
  @IsObject()
  token0: TokenInfoDto;

  @ApiProperty({ type: TokenInfoDto })
  @ValidateNested()
  @Type(() => TokenInfoDto)
  @IsObject()
  token1: TokenInfoDto;

  @ApiProperty({ example: '1700000000', description: 'Timestamp de criação do pool' })
  @IsNumberString()
  createdAtTimestamp: string;

  @ApiProperty({ type: [PoolDayDataDto], description: 'Daily data for the pool' })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PoolDayDataDto)
  poolDayData: PoolDayDataDto[];
}

export class UniswapPoolsResponseDto {
  @ApiProperty({ type: [UniswapPoolResponseDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => UniswapPoolResponseDto)
  pools: UniswapPoolResponseDto[];

  @ApiProperty({ example: 22360835, description: 'Block number used for the query' })
  @IsNumberString()
  blockNumber: string;
}