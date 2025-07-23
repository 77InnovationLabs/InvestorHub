export interface NetworkConfig {
    usdToken: {
        address: string;
        decimals: number;
    };
    quoterContract: string;
    name: string;
}