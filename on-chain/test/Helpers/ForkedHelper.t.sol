// //SPDX-License-Identifier: MIT
// pragma solidity 0.8.26;

// //Foundry Stuff
// import { console } from "forge-std/console.sol";

// //Helpers
// import { BaseTests } from "./BaseTests.t.sol";

// ///Protocol Scripts
// import { HelperConfig } from "script/Helpers/HelperConfig.sol";
// import { DeployInit } from "script/DeployInit.s.sol";
// //--> Dex


// //--> Stake





// //Protocol contracts
// import { DiamondCutFacet } from "src/diamond/DiamondCutFacet.sol";
// import { DiamondLoupeFacet } from "src/diamond/DiamondLoupeFacet.sol";
// import { IStartSwapFacet  } from "src/interfaces/UniswapV3/IStartSwapFacet.sol";
// ///Interfaces
// import { IStartPositionFacet, INonFungiblePositionManager } from "src/interfaces/UniswapV3/IStartPositionFacet.sol";

// ///Open Zeppelin Tools
// import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


// contract ForkedHelper is BaseTests {

//     string BASE_SEPOLIA_RPC_URL = vm.envString("BASE_SEPOLIA_RPC");
//     string BASE_MAINNET_RPC_URL = vm.envString("BASE_MAINNET_RPC");
//     string ARBITRUM_SEPOLIA_RPC_URL = vm.envString("ARB_SEPOLIA_RPC");
//     string ARBITRUM_MAINNET_RPC_URL = vm.envString("ARB_MAINNET_RPC");
//     uint256 baseSepolia;
//     uint256 baseMainnet;
//     uint256 arbSepolia;
//     uint256 arbMainnet;

//     HelperConfig.NetworkConfig s_baseConfig;
//     HelperConfig.NetworkConfig s_arbConfig;

//     ///Mainnet variables
//     IERC20 constant USDC_BASE_MAINNET = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);
//     IERC20 constant WETH_BASE_MAINNET = IERC20(0x4200000000000000000000000000000000000006);
    
//     IERC20 constant ARB_USDC_MAINNET = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
//     IERC20 constant ARB_WETH_MAINNET = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

//     ///@notice Uniswap pool fee
//     uint24 constant USDC_WETH_POOL_FEE = 500; //0.05%
//     ///@notice Pool Range
//     int24 constant MIN_TICK = -203110; // Minimum price range
//     int24 constant MAX_TICK = -191200;  // Maximum price range
//     ///@notice Token created at the block previously defined.
//     uint256 s_tokenId = 2935624;
//     uint128 s_liquidity = 107147261666102;

//     ///Token Amounts
//     uint256 constant USDC_INITIAL_BALANCE = 10_000*10**6;
//     uint256 constant WETH_INITIAL_BALANCE = 100 * 10**18;

//     function setUp() public override {

//         /*/////////////////////////////////////////////////
//                 CREATE BASE FORK E DEPLOY CONTRACTS V3
//         //////////////////////////////////////////////////*/
//         baseMainnet = vm.createSelectFork(BASE_MAINNET_RPC_URL);
//         vm.rollFork(29_441_000);

//         s_deploy = new DeployInit();

//         (s_helperConfig,s_diamond) = s_deploy.run();

//         ///Base Network Configs
//         s_baseConfig = s_helperConfig.getConfig();

//         ///Wrappers
//         s_uniSwapWrapper = IStartSwapFacet(address(s_diamond));
//         s_uniStakeWrapper = IStartPositionFacet(address(s_diamond));

//         ///Distribute some USDC using the Coinbase Wallet
//         vm.startPrank(BASE_USDC_HOLDER);
//         USDC_BASE_MAINNET.transfer(s_user02, USDC_INITIAL_BALANCE);
//         USDC_BASE_MAINNET.transfer(s_user03, USDC_INITIAL_BALANCE);
//         USDC_BASE_MAINNET.transfer(s_user04, USDC_INITIAL_BALANCE);
//         USDC_BASE_MAINNET.transfer(s_user05, USDC_INITIAL_BALANCE);
//         vm.stopPrank();

//         //Distribute eth balance
//         vm.deal(s_user02, WETH_INITIAL_BALANCE);
//         vm.deal(s_user03, WETH_INITIAL_BALANCE);
//         vm.deal(s_user04, WETH_INITIAL_BALANCE);

//         // Labeling
//         vm.label(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913, "USDC Contract");
//         vm.label(0x4200000000000000000000000000000000000006, "wETH Contract");

//         /*/////////////////////////////////////////////////
//                 CREATE ARB FORK E DEPLOY CONTRACTS V2
//         //////////////////////////////////////////////////*/

//         arbMainnet = vm.createSelectFork(ARBITRUM_MAINNET_RPC_URL);
//         vm.rollFork(330_415_000);

//         s_deploy = new DeployInit();
//         (s_helperConfigArb,s_diamondArb) = s_deploy.run();

//         s_arbConfig = s_helperConfigArb.getConfig();

//         ///Wrappers
//         s_uniSwapWrapperArb = IStartSwapFacet(address(s_diamondArb));
//         s_uniStakeWrapperArb = IStartPositionFacet(address(s_diamondArb));

//         ///Distribute some USDC using the Binance Wallet
//         vm.startPrank(ARB_USDC_HOLDER);
//         ARB_USDC_MAINNET.transfer(s_user02, USDC_INITIAL_BALANCE);
//         ARB_USDC_MAINNET.transfer(s_user03, USDC_INITIAL_BALANCE);
//         ARB_USDC_MAINNET.transfer(s_user04, USDC_INITIAL_BALANCE);
//         ARB_USDC_MAINNET.transfer(s_user05, USDC_INITIAL_BALANCE);
//         vm.stopPrank();

//         // Labeling
//         vm.label(0xaf88d065e77c8cC2239327C5EDb3A432268e5831, "USDC Contract");
//         vm.label(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1, "wETH Contract");
//     }

//     modifier baseMainnetMod(){
//         vm.selectFork(baseMainnet);
//         _;
//     }

//     modifier basePositionOpener(){
//         bytes memory path = abi.encodePacked(address(USDC_BASE_MAINNET), USDC_WETH_POOL_FEE, address(WETH_BASE_MAINNET));
//         uint256 totalAmountIn = 6000*10**6;
//         uint256 amountInSwap = 1850*10**6;
//         uint256 amountOutSwap = 1*10**18;

//         IStartSwapFacet.DexPayload memory dexPayload = IStartSwapFacet.DexPayload({
//             path: path,
//             amountInForInputToken: amountInSwap,
//             deadline: 0
//         });

//         INonFungiblePositionManager.MintParams memory stakePayload = INonFungiblePositionManager.MintParams({
//             token0: address(USDC_BASE_MAINNET),
//             token1: address(WETH_BASE_MAINNET),
//             fee: USDC_WETH_POOL_FEE,
//             tickLower: MIN_TICK,
//             tickUpper: MAX_TICK,
//             amount0Desired: amountInSwap,
//             amount1Desired: amountOutSwap,
//             amount0Min: 0,
//             amount1Min: 0,
//             recipient: s_user02,
//             deadline: block.timestamp + 600
//         });

//         vm.startPrank(s_user02);
//         USDC_BASE_MAINNET.approve(address(s_uniSwapWrapper), totalAmountIn);
//         s_uniSwapWrapper.startSwap(totalAmountIn, dexPayload, stakePayload);
//         vm.stopPrank();
        
//         _;
//     }

//     modifier arbMainnetMod(){
//         vm.selectFork(arbMainnet);
//         _;
//     }

//     modifier arbPositionOpener(){
//         bytes memory path = abi.encodePacked(address(ARB_USDC_MAINNET), USDC_WETH_POOL_FEE, address(ARB_WETH_MAINNET));
//         uint256 totalAmountIn = 6000*10**6;
//         uint256 amountInSwap = 1850*10**6;
//         uint256 amountOutSwap = 1*10**18;

//         assertEq(ARB_USDC_MAINNET.balanceOf(address(s_uniSwapWrapper)), 0);
//         assertEq(ARB_WETH_MAINNET.balanceOf(address(s_uniSwapWrapper)), 0);

//         assertEq(ARB_USDC_MAINNET.balanceOf(address(s_multiSig)), 0);
//         uint256 initialWEthBalance = ARB_WETH_MAINNET.balanceOf(address(s_multiSig));

//         IStartSwapFacet.DexPayload memory dexPayload = IStartSwapFacet.DexPayload({
//             path: path,
//             amountInForInputToken: amountInSwap,
//             deadline: block.timestamp + 60
//         });

//         INonFungiblePositionManager.MintParams memory stakePayload = INonFungiblePositionManager.MintParams({
//             token0: address(ARB_USDC_MAINNET),
//             token1: address(ARB_WETH_MAINNET),
//             fee: USDC_WETH_POOL_FEE,
//             tickLower: MIN_TICK,
//             tickUpper: MAX_TICK,
//             amount0Desired: amountInSwap,
//             amount1Desired: amountOutSwap,
//             amount0Min: 0,
//             amount1Min: 0,
//             recipient: s_user02,
//             deadline: block.timestamp + 60
//         });

//         vm.startPrank(s_user02);
//         ARB_USDC_MAINNET.approve(address(s_uniSwapWrapperArb), totalAmountIn);
//         s_uniSwapWrapperArb.startSwap(totalAmountIn, dexPayload, stakePayload);
//         vm.stopPrank();

//         ///Ensure the Multisig receives the protocol fee
//         assertGt(ARB_USDC_MAINNET.balanceOf(address(s_multiSig)), (amountInSwap / 50));
//         assertGt(ARB_WETH_MAINNET.balanceOf(address(s_multiSig)), (amountOutSwap / 50));
//         ///Ensure protocol doesn't hold any asset
//         assertEq(ARB_USDC_MAINNET.balanceOf(address(s_uniSwapWrapperArb)), 0);
//         assertEq(ARB_WETH_MAINNET.balanceOf(address(s_uniSwapWrapperArb)), 0);
        
//         _;
//     }
// }