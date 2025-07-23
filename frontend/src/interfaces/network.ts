export interface Network {
    id: string;
    name: string;
    chainId: number;
    rpcUrl: string;
    graphqlUrl: string;
    currency: string;
    positionManagerAddress: string;
    factoryAddress: string;
    isActive: boolean;
}