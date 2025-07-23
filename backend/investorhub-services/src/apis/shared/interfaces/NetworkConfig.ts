export interface NetworkConfig {
    positionManagerAddress: string;
    providerUrl: string;
    factoryAddress: string;
    quoterContract: string;
    usdToken: {
        address: string;
        symbol: string;
        decimals: number;
    };
}