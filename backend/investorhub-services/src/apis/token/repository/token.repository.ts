import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Token } from '../../../database/schemas/token.schema';
import { BaseRepository } from '../../../database/repositories/base.repository';

@Injectable()
export class TokenRepository extends BaseRepository<Token> {
  constructor(
    @InjectModel(Token.name) private readonly tokenModel: Model<Token>,
  ) {
    super(tokenModel);
  }

  async findByAddress(address: string): Promise<Token | null> {
    return this.tokenModel.findOne({ address }).populate('network').exec();
  }

  async findBySymbol(symbol: string): Promise<Token | null> {
    return this.tokenModel.findOne({ symbol }).populate('network').exec();
  }

  async findByName(name: string): Promise<Token | null> {
    return this.tokenModel.findOne({ name }).populate('network').exec();
  }

  async findAll(): Promise<Token[]> {
    return this.tokenModel.find().populate('network').exec();
  }

  async findById(id: string): Promise<Token | null> {
    return this.tokenModel.findById(id).populate('network').exec();
  }

  async findByNetworkId(networkId: string): Promise<Token[]> {
    // Convert string to ObjectId if it's a valid ObjectId string
    const objectId = Types.ObjectId.isValid(networkId) ? new Types.ObjectId(networkId) : networkId;
    console.log('Searching for tokens with networkId:', networkId);
    console.log('Converted to ObjectId:', objectId);
    
    const tokens = await this.tokenModel.find({ network: objectId }).populate('network').exec();
    console.log('Found tokens:', tokens.length);
    return tokens;
  }
} 