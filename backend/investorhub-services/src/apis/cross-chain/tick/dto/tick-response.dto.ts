import { ApiProperty } from '@nestjs/swagger';

export class TickValuesResponseDto {
  @ApiProperty({
    example: -887220,
    description: 'Minimum tick value for the pool, aligned to tick spacing.'
  })
  minTick: number;

  @ApiProperty({
    example: 887220,
    description: 'Maximum tick value for the pool, aligned to tick spacing.'
  })
  maxTick: number;

  @ApiProperty({
    example: 60,
    description: 'Tick spacing for the pool.'
  })
  tickSpacing: number;
} 