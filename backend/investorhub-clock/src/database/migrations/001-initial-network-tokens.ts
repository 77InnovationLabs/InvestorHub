import { NetworkConfigRepository } from '../repositories/network-config.repository';
import { TokenRepository } from '../repositories/token.repository';
import { MigrationRepository } from '../repositories/migration.repository';

export const name = '001-initial-network-tokens';

export async function up(
  networkConfigRepository: NetworkConfigRepository,
  tokenRepository: TokenRepository,
  migrationRepository: MigrationRepository,
): Promise<void> {
  // Check if migration was already executed
  const existingMigration = await migrationRepository.findOne({ name });
  if (existingMigration) {
    console.log(`Migration ${name} was already executed`);
    return;
  }

  // Create network configs
  const ethereumNetwork = await networkConfigRepository.create({
    name: 'Ethereum Mainnet',
    chainId: 1,
    rpcUrl: 'https://eth.llamarpc.com',
    graphqlUrl: 'https://gateway.thegraph.com/api/subgraphs/id/5zvR82QoaXYFyDEKLZ9t6v9adgnptxYpKpSbxtgVENFV',
    currency: 'ETH',
    positionManagerAddress: '0xC36442b4a4522E871399CD717aBDD847Ab11FE88',
    factoryAddress: '0x1F98431c8aD98523631AE4a59f267346ea31F984',
    isActive: true,
  });

  const baseNetwork = await networkConfigRepository.create({
    name: 'Base Mainnet',
    chainId: 8453,
    rpcUrl: 'https://mainnet.base.org',
    graphqlUrl: 'https://gateway.thegraph.com/api/subgraphs/id/HMuAwufqZ1YCRmzL2SfHTVkzZovC9VL2UAKhjvRqKiR1',
    currency: 'ETH',
    positionManagerAddress: '0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1',
    factoryAddress: '0x33128a8fC17869897dcE68Ed026d694621f6FDfD',
    isActive: true,
  });

  const sepoliaNetwork = await networkConfigRepository.create({
    name: 'Sepolia',
    chainId: 11155111,
    rpcUrl: 'https://1rpc.io/sepolia',
    graphqlUrl: 'https://gateway.thegraph.com/api/subgraphs/id/EDJCBpDBGBajTP1x3qLGLg3ZaVR5Q2TkNxyNHdCuryex',
    currency: 'ETH',
    positionManagerAddress: '0x1238536071E1c677A632429e3655c799b22cDA52',
    factoryAddress: '0x0227628f3F023bb0B980b67D528571c95c6DaC1c',
    isActive: true,
  });

  const baseSepoliaNetwork = await networkConfigRepository.create({
    name: 'Base Sepolia',
    chainId: 84532,
    rpcUrl: 'https://sepolia.base.org',
    graphqlUrl: 'https://gateway.thegraph.com/api/subgraphs/id/ByS2RA4Qfpwrtu9vJC5VQqBN4jQxbM6hugm5VNNspstj',
    currency: 'ETH',
    positionManagerAddress: '0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2',
    factoryAddress: '0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24',
    isActive: true,
  });

  // Token addresses
  const tokenAddresses = {
    // ethereum: {
    //   weth: '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2',
    //   usdt: '0xdac17f958d2ee523a2206206994597c13d831ec7',
    //   usdc: '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',
    //   wbtc: '0x2260fac5e5542a773aa44fbcfedf7c193bc2c599',
    //   link: '0x514910771af9ca656af840dff83e8264ecf986ca',
    // },
    // base: {
    //   weth: '0x4200000000000000000000000000000000000006',
    //   usdt: '0x50c5725949a6f0c72e6c4a641f24049a917db0cb',
    //   usdc: '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913',
    //   wbtc: '0x1d1c4b7b4f5b5b5b5b5b5b5b5b5b5b5b5b5b5b5',
    //   link: '0x88fb150bdc53a65fe94dea0c9ba0a6daf8c6e196',
    // },
    sepolia: {
      weth: '0xfff9976782d46cc05630d1f6ebab18b2324d6b14',
      usdt: '0xaa8e23fb1079ea71e0a56f48a2aa51851d8433d0',
      usdc: '0x1c7d4b196cb0c7b01d743fbc6116a902379c7238',
      wbtc: '0x29f2d40b0605204364af54ec677bd022da425d03',
      link: '0x779877a7b0d9e8603169ddbd7836e478b4624789',
    },
    baseSepolia: {
      weth: '0x4200000000000000000000000000000000000006',
      usdt: '0x036CbD53842c5426634e7929541eC2318f3dCF7e',
      usdc: '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913',
      wbtc: '0xEdd151d22c219a7c13321d4F66A4b779B982dE5f',
      link: '0xE4aB69C077896252FAFBD49EFD26B5D171A32410',
    },
  };

  // if (ethereumNetwork && ethereumNetwork._id) {
  //   // Create tokens for Ethereum
  //   await tokenRepository.createMany([
  //     {
  //       name: 'Wrapped Ether',
  //       symbol: 'WETH',
  //       address: tokenAddresses.ethereum.weth,
  //       network: ethereumNetwork._id,
  //     },
  //     {
  //       name: 'Tether USD',
  //       symbol: 'USDT',
  //       address: tokenAddresses.ethereum.usdt,
  //       network: ethereumNetwork._id,
  //     },
  //     {
  //       name: 'USD Coin',
  //       symbol: 'USDC',
  //       address: tokenAddresses.ethereum.usdc,
  //       network: ethereumNetwork._id,
  //     },
  //     {
  //       name: 'Wrapped Bitcoin',
  //       symbol: 'WBTC',
  //       address: tokenAddresses.ethereum.wbtc,
  //       network: ethereumNetwork._id,
  //     },
  //     {
  //       name: 'Chainlink',
  //       symbol: 'LINK',
  //       address: tokenAddresses.ethereum.link,
  //       network: ethereumNetwork._id,
  //     },
  //   ]);
  // }

  // if (baseNetwork && baseNetwork._id) {
  //   // Create tokens for Base
  //   await tokenRepository.createMany([
  //     {
  //       name: 'Wrapped Ether',
  //       symbol: 'WETH',
  //       address: tokenAddresses.base.weth,
  //       network: baseNetwork._id,
  //     },
  //     {
  //       name: 'Tether USD',
  //       symbol: 'USDT',
  //       address: tokenAddresses.base.usdt,
  //       network: baseNetwork._id,
  //     },
  //     {
  //       name: 'USD Coin',
  //       symbol: 'USDC',
  //       address: tokenAddresses.base.usdc,
  //       network: baseNetwork._id,
  //     },
  //     {
  //       name: 'Wrapped Bitcoin',
  //       symbol: 'WBTC',
  //       address: tokenAddresses.base.wbtc,
  //       network: baseNetwork._id,
  //     },
  //     {
  //       name: 'Chainlink',
  //       symbol: 'LINK',
  //       address: tokenAddresses.base.link,
  //       network: baseNetwork._id,
  //     },
  //   ]);
  // }

  if (sepoliaNetwork && sepoliaNetwork._id) {
    // Create tokens for Sepolia
    await tokenRepository.createMany([
      {
        name: 'Wrapped Ether',
        symbol: 'WETH',
        address: tokenAddresses.sepolia.weth,
        network: sepoliaNetwork._id,
        whitelist: true,
      },
      {
        name: 'Tether USD',
        symbol: 'USDT',
        address: tokenAddresses.sepolia.usdt,
        network: sepoliaNetwork._id,
        whitelist: true,
      },
      {
        name: 'USD Coin',
        symbol: 'USDC',
        address: tokenAddresses.sepolia.usdc,
        network: sepoliaNetwork._id,
        whitelist: true,
      },
      {
        name: 'Wrapped Bitcoin',
        symbol: 'WBTC',
        address: tokenAddresses.sepolia.wbtc,
        network: sepoliaNetwork._id,
        whitelist: true,
      },
      {
        name: 'Chainlink',
        symbol: 'LINK',
        address: tokenAddresses.sepolia.link,
        network: sepoliaNetwork._id,
        whitelist: true,
      },
    ]);
  }

  if (baseSepoliaNetwork && baseSepoliaNetwork._id) {
    // Create tokens for Base Sepolia
    await tokenRepository.createMany([
      {
        name: 'Wrapped Ether',
        symbol: 'WETH',
        address: tokenAddresses.baseSepolia.weth,
        network: baseSepoliaNetwork._id,
        whitelist: true,
      },
      {
        name: 'Tether USD',
        symbol: 'USDT',
        address: tokenAddresses.baseSepolia.usdt,
        network: baseSepoliaNetwork._id,
        whitelist: true,
      },
      {
        name: 'USD Coin',
        symbol: 'USDC',
        address: tokenAddresses.baseSepolia.usdc,
        network: baseSepoliaNetwork._id,
        whitelist: true,
      },
      {
        name: 'Wrapped Bitcoin',
        symbol: 'WBTC',
        address: tokenAddresses.baseSepolia.wbtc,
        network: baseSepoliaNetwork._id,
        whitelist: true,
      },
      {
        name: 'Chainlink',
        symbol: 'LINK',
        address: tokenAddresses.baseSepolia.link,
        network: baseSepoliaNetwork._id,
        whitelist: true,
      },
    ]);
  }

  // Record migration
  await migrationRepository.create({
    name,
    executedAt: new Date(),
  });

  console.log(`Migration ${name} executed successfully`);
}

export async function down(
  networkConfigRepository: NetworkConfigRepository,
  tokenRepository: TokenRepository,
  migrationRepository: MigrationRepository,
): Promise<void> {
  // Remove all tokens
  await tokenRepository.deleteMany({});
  
  // Remove network configs
  await networkConfigRepository.deleteMany({});
  
  // Remove migration record
  await migrationRepository.deleteOne({ name });
  
  console.log(`Migration ${name} reverted successfully`);
} 