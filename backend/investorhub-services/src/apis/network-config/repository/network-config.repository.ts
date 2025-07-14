import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { NetworkConfig } from '../../../database/schemas/network-config.schema';
import { BaseRepository } from '../../../database/repositories/base.repository';

@Injectable()
export class NetworkConfigRepository extends BaseRepository<NetworkConfig> {
  constructor(
    @InjectModel(NetworkConfig.name) private readonly networkConfigModel: Model<NetworkConfig>,
  ) {
    super(networkConfigModel);
  }

  async findByName(name: string): Promise<NetworkConfig | null> {
    return this.networkConfigModel.findOne({ name }).exec();
  }

  async findByGraphqlUrl(graphqlUrl: string): Promise<NetworkConfig | null> {
    return this.networkConfigModel.findOne({ graphqlUrl }).exec();
  }

  async findAll(): Promise<NetworkConfig[]> {
    return this.networkConfigModel.find().exec();
  }

  async findById(id: string): Promise<NetworkConfig | null> {
    return this.networkConfigModel.findById(id).exec();
  }

  async findByChainId(chainId: number): Promise<NetworkConfig | null> {
    return this.networkConfigModel.findOne({ chainId }).exec();
  }
} 