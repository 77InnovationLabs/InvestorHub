import { Module } from '@nestjs/common';
import { UniswapCalculatorController } from './uniswap-calculator.controller';
import { UniswapMathService } from './uniswap-math.service';
import { UniswapCalculatorService } from './uniswap-calculator.service';
import { NetworkConfigModule } from '../network-config/network-config.module';

@Module({
  imports: [NetworkConfigModule],
  controllers: [UniswapCalculatorController],
  providers: [UniswapMathService, UniswapCalculatorService],
  exports: [UniswapMathService, UniswapCalculatorService],
})
export class UniswapCalculatorModule {} 