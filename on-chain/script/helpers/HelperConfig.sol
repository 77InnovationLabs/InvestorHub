// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Script, console } from "forge-std/Script.sol";

contract HelperConfig is Script {
    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/
    struct NetworkConfig {
        address admin;
        address vault;
        address multisig;
        address ownershipFacet;
        address cutFacet;
        address loupeFacet;
        address diamond;
        address initializer; //@question is needed? TODO: Ensure this initializer is needed.
        address usdc;
        DexSpecifications dex;
        StakingSpecifications stake;
        ChainlinkInfos cl;
    }

    struct DexSpecifications{
        address routerUniV3;
    }

    struct StakingSpecifications{
        address aavePool;
        address compoundController;
        address uniswapFactory;
        address uniswapV3PositionManager;
    }

    struct ChainlinkInfos{
        address ccipRouter;
        address linkToken;
        address feedsAggregator;
        uint24 heartbeat;
        address functionsRouter;
        bytes32 donId;
        uint64 subscriptionId;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    // Magic Number Removal
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    uint256 public constant BASE_MAINNET_CHAIN_ID = 8453;
    uint256 public constant ARBITRUM_MAINNET_CHAIN_ID = 42161;
    uint256 public constant FUJI_CHAIN_ID = 43113;
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant BASE_SEPOLIA_CHAIN_ID = 84532;

    // Local network state variables
    NetworkConfig public s_localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public s_networkConfigs;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error HelperConfig__InvalidChainId();


    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor() {
        // Not initiating any chain on constructor
        s_networkConfigs[ARBITRUM_MAINNET_CHAIN_ID] = getMainnetArbitrumConfig();
        s_networkConfigs[BASE_MAINNET_CHAIN_ID] = getMainnetBaseConfig();
        s_networkConfigs[FUJI_CHAIN_ID] = getFujiConfig();
        s_networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaConfig();
        s_networkConfigs[BASE_SEPOLIA_CHAIN_ID] = getBaseSepoliaConfig();
    }

    function setConfig(uint256 chainId, NetworkConfig memory networkConfig) public {
        s_networkConfigs[chainId] = networkConfig;
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 _chainId) public returns (NetworkConfig memory) {
        if (_chainId != LOCAL_CHAIN_ID) {
            return s_networkConfigs[_chainId];
        } else if(s_networkConfigs[_chainId].diamond != address(0)) {
            return s_networkConfigs[_chainId];
        } else if (_chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    /*///////////////////////////////////
                    MAINNETS
    ///////////////////////////////////*/
    function getMainnetBaseConfig() public view returns (NetworkConfig memory mainnetNetworkConfig) {
        mainnetNetworkConfig = NetworkConfig({
            admin: vm.envAddress("ADMIN_TESTNET_PUBLIC_KEY"),
            multisig: vm.envAddress("MULTISIG_TESTNET_FAKE_ADDRESS"),
            vault: vm.envAddress("VAULT_TESTNET_FAKE_ADDRESS"), //update with the address in the future
            ownershipFacet: address(0),
            cutFacet: address(0),
            loupeFacet: address(0),
            diamond: address(0),
            initializer: address(0),
            usdc: 	0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913,
            dex: DexSpecifications({
                routerUniV3: 0x2626664c2603336E57B271c5C0b26F421741e481
            }),
            stake: StakingSpecifications({
                aavePool: address(0),
                compoundController: address(0),
                uniswapFactory: 0x33128a8fC17869897dcE68Ed026d694621f6FDfD,
                uniswapV3PositionManager: 0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1
            }),
            cl: ChainlinkInfos({
                ccipRouter: 0x881e3A65B4d4a04dD529061dd0071cf975F58bCD,
                linkToken: 0x88Fb150BDc53A65fe94Dea0c9BA0a6dAf8C6e196,
                feedsAggregator: 0x17CAb8FE31E32f08326e5E27412894e49B0f9D65,
                heartbeat: 86_400,
                functionsRouter: 0xf9B8fc078197181C841c296C876945aaa425B278,
                donId: 0x66756e2d626173652d6d61696e6e65742d310000000000000000000000000000,
                subscriptionId: 0 //TODO: create programmatically
            })
        });
    }

    function getMainnetArbitrumConfig() public view returns (NetworkConfig memory mainnetNetworkConfig) {

        mainnetNetworkConfig = NetworkConfig({
            admin: vm.envAddress("ADMIN_TESTNET_PUBLIC_KEY"),
            multisig: vm.envAddress("MULTISIG_TESTNET_FAKE_ADDRESS"), //Burner Wallet for Forked Tests
            vault: vm.envAddress("VAULT_TESTNET_FAKE_ADDRESS"), //update with the address in the future
            ownershipFacet: address(0),
            cutFacet: address(0),
            loupeFacet: address(0),
            diamond: address(0),
            initializer: address(0),
            usdc: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831,
            dex: DexSpecifications({
                routerUniV3: 0xE592427A0AEce92De3Edee1F18E0157C05861564
            }),
            stake: StakingSpecifications({
                aavePool: address(0),
                compoundController: address(0),
                uniswapFactory: 0x1F98431c8aD98523631AE4a59f267346ea31F984,
                uniswapV3PositionManager: 0xC36442b4a4522E871399CD717aBDD847Ab11FE88
            }),
            cl: ChainlinkInfos({
                ccipRouter: 0x141fa059441E0ca23ce184B6A78bafD2A517DdE8,
                linkToken: 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4,
                feedsAggregator: 0x86E53CF1B870786351Da77A57575e79CB55812CB,
                heartbeat: 3_600,
                functionsRouter: 0x97083E831F8F0638855e2A515c90EdCF158DF238,
                donId: 0x66756e2d617262697472756d2d6d61696e6e65742d3100000000000000000000,
                subscriptionId: 0 //TODO: create programmatically
            })
        });
    }

    /*///////////////////////////////////
                    TESTNETS
    ///////////////////////////////////*/
    function getFujiConfig() public view returns (NetworkConfig memory fujiNetworkConfig_) {

        fujiNetworkConfig_ = NetworkConfig({
            admin: vm.envAddress("ADMIN_TESTNET_PUBLIC_KEY"),
            multisig: vm.envAddress("MULTISIG_TESTNET_FAKE_ADDRESS"), //Burner Wallet for Forked Tests
            vault: address(0),
            ownershipFacet: address(0),
            cutFacet: address(0),
            loupeFacet: address(0),
            diamond: address(0),
            initializer: address(0),
            usdc: 0x5425890298aed601595a70AB815c96711a31Bc65,
            dex: DexSpecifications({
                routerUniV3: 0xE592427A0AEce92De3Edee1F18E0157C05861564
            }),
            stake: StakingSpecifications({
                aavePool: address(0),
                compoundController: address(0),
                uniswapFactory: address(0),
                uniswapV3PositionManager: address(0)
            }),
            cl: ChainlinkInfos({
                ccipRouter: 0xF694E193200268f9a4868e4Aa017A0118C9a8177,
                linkToken: 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846,
                feedsAggregator: 0x34C4c526902d88a3Aa98DB8a9b802603EB1E3470,
                heartbeat: 86_400,
                functionsRouter: 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0,
                donId: 0x66756e2d6176616c616e6368652d66756a692d31000000000000000000000000,
                subscriptionId: 1212
            })
        });
    }

    function getSepoliaConfig() public view returns (NetworkConfig memory sepoliaNetworkConfig_) {
        sepoliaNetworkConfig_ = NetworkConfig({
            admin: vm.envAddress("ADMIN_TESTNET_PUBLIC_KEY"),
            multisig: vm.envAddress("MULTISIG_TESTNET_FAKE_ADDRESS"), //Burner Wallet for Forked Tests
            vault: 0xacEa951B2E9b58Ce7914044Eaf41E2a4D04c7748,
            ownershipFacet: 0x81Fd19D151F50668676209885Ae51Ee4960cdE48,
            cutFacet: 0xA51eB2B94f1a5484f6Ce008BC966aA4E304acd9E,
            loupeFacet: 0xCb04B49F7b91346A95b6529baddF0468E100c16B,
            diamond: 0x7a91f129E8837f4E464bF80C95ebf770232cC917,
            initializer: 0xDF407457648A2aa756346461C13Db181325b6bd7,
            usdc: 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238,
            dex: DexSpecifications({
                routerUniV3: 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E
            }),
            stake: StakingSpecifications({
                aavePool: address(0),
                compoundController: address(0),
                uniswapFactory: 0x0227628f3F023bb0B980b67D528571c95c6DaC1c,
                uniswapV3PositionManager: 0x1238536071E1c677A632429e3655c799b22cDA52
            }),
            cl: ChainlinkInfos({
                ccipRouter: 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59,
                linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                feedsAggregator: 0xc59E3633BAAC79493d908e63626716e204A45EdF,
                heartbeat: 3_600,
                functionsRouter: 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0,
                donId: 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000,
                subscriptionId: 4382
            })
        });
    }

    function getBaseSepoliaConfig() public view returns (NetworkConfig memory baseSepoliaNetworkConfig_) {
        baseSepoliaNetworkConfig_ = NetworkConfig({
            admin: vm.envAddress("ADMIN_TESTNET_PUBLIC_KEY"),
            multisig: vm.envAddress("MULTISIG_TESTNET_FAKE_ADDRESS"), //Burner Wallet for Forked Tests
            vault: 0xacEa951B2E9b58Ce7914044Eaf41E2a4D04c7748,
            ownershipFacet: 0xD521d2f02eD5f309248607aAEa47B8835072a253,
            cutFacet: 0x6Cbe125483252D394e152295de1BaD389b7adE4C,
            loupeFacet: 0x6340672A62eD989B90c4fBb399Dc84083d491909,
            diamond: 0xeE5d3c9C0C9F0a93773bAFAADe600B144318b366,
            initializer: 0xA501e51E5902879F28b5Bb6F74B701E7FD997625,
            usdc: 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238,
            dex: DexSpecifications({
                routerUniV3: 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E
            }),
            stake: StakingSpecifications({
                aavePool: address(0),
                compoundController: address(0),
                uniswapFactory: 0x0227628f3F023bb0B980b67D528571c95c6DaC1c,
                uniswapV3PositionManager: 0x1238536071E1c677A632429e3655c799b22cDA52
            }),
            cl: ChainlinkInfos({
                ccipRouter: 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93,
                linkToken: 0xE4aB69C077896252FAFBD49EFD26B5D171A32410,
                feedsAggregator: 0xb113F5A928BCfF189C998ab20d753a47F9dE5A61,
                heartbeat: 1_200,
                functionsRouter: 0xf9B8fc078197181C841c296C876945aaa425B278,
                donId: 0x66756e2d626173652d7365706f6c69612d310000000000000000000000000000,
                subscriptionId: 411
            })
        });
    }

    /*///////////////////////////////////
                    LOCAL
    ///////////////////////////////////*/
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // Check to see if we set an active network config
        if (s_localNetworkConfig.diamond != address(0)) {
            return s_localNetworkConfig;
        }

        //TODO: Deploy that ton of mocks.
        ChainlinkInfos memory cl;

        s_localNetworkConfig = NetworkConfig({
            admin: address(1),
            multisig: address(77),
            vault: address(0),
            ownershipFacet: address(0),
            cutFacet: address(0),
            loupeFacet: address(0),
            diamond: address(0),
            initializer: address(0),
            usdc: address(0),
            dex: DexSpecifications({
                routerUniV3: address(0)
            }),
            stake: StakingSpecifications({
                aavePool: address(0),
                compoundController: address(0),
                uniswapFactory: address(0),
                uniswapV3PositionManager: address(0)
            }),
            cl: cl
        });

        return s_localNetworkConfig;
    }
}