import { Module } from '@nestjs/common';
import { TickController } from './tick.controller';
import { TickService } from './tick.service';

@Module({
  controllers: [TickController],
  providers: [TickService],
  exports: [TickService],
})
export class TickModule {}
