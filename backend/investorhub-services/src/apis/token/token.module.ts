import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { TokenController } from './token.controller';
import { TokenService } from './token.service';
import { Token, TokenSchema } from '../../database/schemas/token.schema';
import { NetworkConfig, NetworkConfigSchema } from '../../database/schemas/network-config.schema';
import { DatabaseModule } from '../../database/database.module';
import { TokenRepository } from './repository/token.repository';
import { NetworkConfigModule } from '../network-config/network-config.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Token.name, schema: TokenSchema },
    ]),
    DatabaseModule,
    NetworkConfigModule,
  ],
  controllers: [TokenController],
  providers: [TokenService, TokenRepository], 
  exports: [TokenService, TokenRepository],
})
export class TokenModule {}
