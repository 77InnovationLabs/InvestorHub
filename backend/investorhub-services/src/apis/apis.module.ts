import { Module } from '@nestjs/common';
import { PoolModule } from './pools/pool.module';
import { SubgraphModule } from './subgraph/subgraph.module';
import { TokenModule } from './token/token.module';
import { UniswapCalculatorModule } from './uniswap-calculator/uniswap-calculator.module';
import { QuoteModule } from './cross-chain/quote/quote.module';
import { TickModule } from './cross-chain/tick/tick.module';

@Module({
  imports: [
    PoolModule,
    TokenModule,
    SubgraphModule,
    UniswapCalculatorModule,
    QuoteModule,
    TickModule,
  ],
  exports: [
    PoolModule,
    TokenModule,
    SubgraphModule,
    UniswapCalculatorModule,
    QuoteModule,
    TickModule,
  ]
})
export class ApisModule {}
