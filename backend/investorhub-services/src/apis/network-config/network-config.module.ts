import { MongooseModule } from "@nestjs/mongoose";
import { NetworkConfig, NetworkConfigSchema } from "src/database/schemas/network-config.schema";
import { NetworkConfigRepository } from "./repository/network-config.repository";
import { DatabaseModule } from "src/database/database.module";
import { Module } from "@nestjs/common";


@Module({
    imports: [
      MongooseModule.forFeature([
        { name: NetworkConfig.name, schema: NetworkConfigSchema },
      ]),
      DatabaseModule,
    ],
    controllers: [],
    providers: [NetworkConfigRepository],
    exports: [NetworkConfigRepository],
  })
  export class NetworkConfigModule {} 