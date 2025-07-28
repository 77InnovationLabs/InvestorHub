import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { Token } from './token.schema';

@Schema({ collection: 'pools', timestamps: true })
export class Pool extends Document {

  declare _id: Types.ObjectId;

  @Prop()
  name?: string;

  @Prop({ required: true })
  feeTier: string;

  @Prop({ type: Types.ObjectId, ref: 'Token', required: true })
  token0: Token | Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Token', required: true })
  token1: Token | Types.ObjectId;

  @Prop()
  block?: string;

  @Prop({ required: true })
  address: string;
}

export const PoolSchema = SchemaFactory.createForClass(Pool);

// Add indexes
PoolSchema.index({ token0: 1 });
PoolSchema.index({ token1: 1 });
PoolSchema.index({ token0: 1, token1: 1, feeTier: 1 }, { unique: true });
