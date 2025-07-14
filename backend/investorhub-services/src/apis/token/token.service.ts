import { Injectable, Logger, NotFoundException, ConflictException } from '@nestjs/common';
import { Token } from '../../database/schemas/token.schema';
import { CreateTokenDto, UpdateTokenDto, TokenResponseDto } from './dto/token-response.dto';
import { TokenRepository } from './repository/token.repository';
import { NetworkConfig } from '../../database/schemas/network-config.schema';
import { NetworkConfigRepository } from '../network-config/repository/network-config.repository';

@Injectable()
export class TokenService {
  private readonly logger = new Logger(TokenService.name);

  constructor(
    private readonly tokenRepository: TokenRepository,
    private readonly networkConfigRepository: NetworkConfigRepository,
  ) {}

  async create(createTokenDto: CreateTokenDto): Promise<TokenResponseDto> {
    try {
      this.logger.log(`Creating token with data: ${JSON.stringify(createTokenDto)}`);
      
      // Verify if network exists
      const network = await this.networkConfigRepository.findById(createTokenDto.networkId);
      if (!network) {
        throw new NotFoundException(`Network with id ${createTokenDto.networkId} not found`);
      }

      const existingToken = await this.tokenRepository.findByAddress(createTokenDto.address);
      if (existingToken) {
        throw new ConflictException('Token with this symbol or name already exists');
      }

      const { networkId, ...tokenData } = createTokenDto;
      const savedToken = await this.tokenRepository.create({
        ...tokenData,
        network: network as NetworkConfig,
      });
      
      this.logger.log(`Token created successfully with id: ${savedToken.id}`);
      return this.mapToResponseDto(savedToken);
    } catch (error) {
      this.logger.error(`Error creating token: ${error.message}`, error.stack);
      throw error;
    }
  }

  async findAll(chainId?: number, whitelist?: boolean): Promise<TokenResponseDto[]> {
    try {
      this.logger.log(`Fetching tokens${chainId ? ` for chainId: ${chainId}` : ''}${whitelist !== undefined ? ` with whitelist: ${whitelist}` : ''}`);
      
      let tokens: Token[];
      
      if (chainId) {
        // Find network by chainId first
        const network = await this.networkConfigRepository.findByChainId(chainId);
        if (!network) {
          throw new NotFoundException(`Network with chainId ${chainId} not found`);
        }
        
        // Get tokens for this network
        tokens = await this.tokenRepository.findByNetworkId(network._id.toString());
      } else {
        // Get all tokens
        tokens = await this.tokenRepository.findAll();
      }
      
      // Filter by whitelist status if specified
      if (whitelist !== undefined) {
        tokens = tokens.filter(token => token.whitelist === whitelist);
      }
      
      this.logger.log(`Found ${tokens.length} tokens`);
      return tokens.map(token => this.mapToResponseDto(token));
    } catch (error) {
      this.logger.error(`Error fetching tokens: ${error.message}`, error.stack);
      throw error;
    }
  }

  async findOne(id: string): Promise<TokenResponseDto> {
    try {
      this.logger.log(`Fetching token with id: ${id}`);
      const token = await this.tokenRepository.findById(id);
      
      if (!token) {
        throw new NotFoundException(`Token with id ${id} not found`);
      }
      
      this.logger.log(`Token found: ${token.symbol}`);
      return this.mapToResponseDto(token);
    } catch (error) {
      this.logger.error(`Error fetching token with id ${id}: ${error.message}`, error.stack);
      throw error;
    }
  }

  async findBySymbol(symbol: string): Promise<TokenResponseDto> {
    try {
      this.logger.log(`Fetching token with symbol: ${symbol}`);
      const token = await this.tokenRepository.findBySymbol(symbol);
      
      if (!token) {
        throw new NotFoundException(`Token with symbol ${symbol} not found`);
      }
      
      this.logger.log(`Token found: ${token.name}`);
      return this.mapToResponseDto(token);
    } catch (error) {
      this.logger.error(`Error fetching token with symbol ${symbol}: ${error.message}`, error.stack);
      throw error;
    }
  }

  async update(id: string, updateTokenDto: UpdateTokenDto): Promise<TokenResponseDto> {
    try {
      this.logger.log(`Updating token with id: ${id}, data: ${JSON.stringify(updateTokenDto)}`);
      
      const { networkId, ...updateData } = updateTokenDto;
      let network: NetworkConfig | undefined;

      if (networkId) {
        const foundNetwork = await this.networkConfigRepository.findById(networkId);
        if (!foundNetwork) {
          throw new NotFoundException(`Network with id ${networkId} not found`);
        }
        network = foundNetwork;
      }

      const token = await this.tokenRepository.update(
        id,
        { 
          ...updateData,
          ...(network && { network: network as NetworkConfig }),
        }
      );
      
      if (!token) {
        throw new NotFoundException(`Token with id ${id} not found`);
      }
      
      this.logger.log(`Token updated successfully: ${token.symbol}`);
      return this.mapToResponseDto(token);
    } catch (error) {
      this.logger.error(`Error updating token with id ${id}: ${error.message}`, error.stack);
      throw error;
    }
  }

  async remove(id: string): Promise<void> {
    try {
      this.logger.log(`Deleting token with id: ${id}`);
      const result = await this.tokenRepository.delete(id);
      
      if (!result) {
        throw new NotFoundException(`Token with id ${id} not found`);
      }
      
      this.logger.log(`Token deleted successfully: ${result.symbol}`);
    } catch (error) {
      this.logger.error(`Error deleting token with id ${id}: ${error.message}`, error.stack);
      throw error;
    }
  }

  private mapToResponseDto(token: Token): TokenResponseDto {
    return {
      id: token.id.toString(),
      name: token.name,
      symbol: token.symbol,
      imageUrl: token.imageUrl,
      address: token.address,
      decimals: token.decimals,
      whitelist: token.whitelist,
      network: {
        id: token.network.id.toString(),
        name: token.network.name,
        graphqlUrl: token.network.graphqlUrl,
      },
    };
  }
}
