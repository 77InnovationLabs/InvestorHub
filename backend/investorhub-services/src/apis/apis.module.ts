import { Module } from '@nestjs/common';
import { PoolModule } from './pools/pool.module';
import { SubgraphModule } from './subgraph/subgraph.module';
import { TokenModule } from './token/token.module';
import { UniswapCalculatorModule } from './uniswap-calculator/uniswap-calculator.module';
import { QuoteModule } from './cross-chain/quote/quote.module';

@Module({
  imports: [
    PoolModule,
    TokenModule,
    SubgraphModule,
    UniswapCalculatorModule,
    QuoteModule,
  ],
  exports: [
    PoolModule,
    TokenModule,
    SubgraphModule,
    UniswapCalculatorModule,
    QuoteModule,
  ]
})
export class ApisModule {}
