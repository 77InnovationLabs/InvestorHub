import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Pool } from '../../../database/schemas/pool.schemas';
import { BaseRepository } from '../../../database/repositories/base.repository';

@Injectable()
export class PoolRepository extends BaseRepository<Pool> {
  constructor(
    @InjectModel(Pool.name) private readonly poolModel: Model<Pool>,
  ) {
    super(poolModel);
  }

  async findByTokenPair(token0Id: string, token1Id: string): Promise<Pool[]> {
    const token0ObjectId = new Types.ObjectId(token0Id);
    const token1ObjectId = new Types.ObjectId(token1Id);

    return this.poolModel.find({
      $or: [
        { token0: token0ObjectId, token1: token1ObjectId },
        { token0: token1ObjectId, token1: token0ObjectId }
      ]
    })
    .populate({
      path: 'token0',
      populate: {
        path: 'network'
      }
    })
    .populate({
      path: 'token1',
      populate: {
        path: 'network'
      }
    })
    .exec();
  }

  async findByTokenAddresses(token0Address: string, token1Address: string): Promise<Pool[]> {
    // Normalize addresses to lowercase
    const normalizedToken0 = token0Address.toLowerCase();
    const normalizedToken1 = token1Address.toLowerCase();

    return this.poolModel.find()
      .populate({
        path: 'token0',
        match: { address: { $in: [normalizedToken0, normalizedToken1] } },
        populate: {
          path: 'network'
        }
      })
      .populate({
        path: 'token1',
        match: { address: { $in: [normalizedToken0, normalizedToken1] } },
        populate: {
          path: 'network'
        }
      })
      .lean()
      .then(pools => {
        // Filter only those where both token0 and token1 were populated
        return pools.filter(pool => pool.token0 && pool.token1);
      });
  }

  async findByTokenIds(tokenIds: string[]): Promise<Pool[]> {
    const objectIds = tokenIds.map(id => new Types.ObjectId(id));
    
    return this.poolModel.find({
      $or: [
        { token0: { $in: objectIds } },
        { token1: { $in: objectIds } }
      ]
    })
    .populate({
      path: 'token0',
      populate: {
        path: 'network'
      }
    })
    .populate({
      path: 'token1',
      populate: {
        path: 'network'
      }
    })
    .exec();
  }

  async findPoolsByTokenAddress(addresses: string[]): Promise<Pool[]> {
    // Normalize all addresses to lowercase
    const normalized = addresses.map(a => a.toLowerCase());

    return this.poolModel.find()
      .populate({
        path: 'token0',
        match: { address: { $in: normalized } },
        populate: {
          path: 'network'
        }
      })
      .populate({
        path: 'token1',
        match: { address: { $in: normalized } },
        populate: {
          path: 'network'
        }
      })
      .then(pools => {
        // Filter only those where token0 or token1 was actually populated
        return pools.filter(pool => pool.token0 || pool.token1);
      });
  }

  async findAll(): Promise<Pool[]> {
    return this.poolModel.find()
      .populate({
        path: 'token0',
        populate: {
          path: 'network'
        }
      })
      .populate({
        path: 'token1',
        populate: {
          path: 'network'
        }
      })
      .exec();
  }

  async findAllWithPagination(page: number = 1, limit: number = 10): Promise<{ pools: Pool[]; total: number; page: number; totalPages: number }> {
    const skip = (page - 1) * limit;
    
    const [pools, total] = await Promise.all([
      this.poolModel.find()
        .populate({
          path: 'token0',
          populate: {
            path: 'network'
          }
        })
        .populate({
          path: 'token1',
          populate: {
            path: 'network'
          }
        })
        .skip(skip)
        .limit(limit)
        .exec(),
      this.poolModel.countDocuments().exec()
    ]);

    return {
      pools,
      total,
      page,
      totalPages: Math.ceil(total / limit)
    };
  }

  async findById(id: string): Promise<Pool | null> {
    return this.poolModel.findById(id)
      .populate({
        path: 'token0',
        populate: {
          path: 'network'
        }
      })
      .populate({
        path: 'token1',
        populate: {
          path: 'network'
        }
      })
      .exec();
  }
} 