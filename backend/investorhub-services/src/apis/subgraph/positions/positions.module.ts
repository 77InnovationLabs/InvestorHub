import { Module } from '@nestjs/common';
import { PositionsController } from './positions.controller';
import { PositionsService } from './positions.service';
import { RedisModule } from '../../../redis/redis.module';
import { MetricsModule } from '../../../metrics/subgraph/metrics.module';
import { GraphQLMainnetModule } from '../graphql/graphql.mainnet.module';

@Module({
  imports: [
    RedisModule,
    GraphQLMainnetModule,
    MetricsModule,
  ],
  controllers: [PositionsController],
  providers: [PositionsService],
  exports: [PositionsService],
})
export class PositionsModule {} 