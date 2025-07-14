// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.26;

// ///Test Helper
// import {ForkedHelper} from "../Helpers/ForkedHelper.t.sol";

// ///Protocol Interfaces
// import { IStartSwapFacet } from "src/interfaces/UniswapV3/IStartSwapFacet.sol";
// import { IStartPositionFacet, INonFungiblePositionManager } from "src/interfaces/UniswapV3/IStartPositionFacet.sol";

// contract UniV3SwapsTest is ForkedHelper {
//     ///Test to ensure UniswapV3 - RouterV3 is functional
//     function test_uniCanSwapOnBaseMainnetFork() public baseMainnetMod {
//         bytes memory path = abi.encodePacked(address(USDC_BASE_MAINNET), USDC_WETH_POOL_FEE, address(WETH_BASE_MAINNET));
//         uint256 totalAmountIn = 6000*10**6;
//         uint256 amountInSwap = 1850*10**6;
//         uint256 amountOutSwap = 1*10**18;

//         assertEq(USDC_BASE_MAINNET.balanceOf(address(s_uniSwapWrapper)), 0);
//         assertEq(WETH_BASE_MAINNET.balanceOf(address(s_uniSwapWrapper)), 0);

//         assertEq(USDC_BASE_MAINNET.balanceOf(address(s_multiSig)), 0);

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

//         ///Ensure the Multisig receives the protocol fee
//         assertGt(USDC_BASE_MAINNET.balanceOf(address(s_multiSig)), (amountInSwap / 50));
//         assertGt(WETH_BASE_MAINNET.balanceOf(address(s_multiSig)), (amountOutSwap / 50));
//         ///Ensure protocol doesn't hold any asset
//         assertEq(USDC_BASE_MAINNET.balanceOf(address(s_uniSwapWrapper)), 0);
//         assertEq(WETH_BASE_MAINNET.balanceOf(address(s_uniSwapWrapper)), 0);
//     }

//     ///Test to ensure UniswapV3 - RouterV2 is functional
//     // function test_uniCanSwapOnArbMainnetFork() public arbMainnetMod {
//     //     bytes memory path = abi.encodePacked(address(ARB_USDC_MAINNET), USDC_WETH_POOL_FEE, address(ARB_WETH_MAINNET));
//     //     uint256 totalAmountIn = 6000*10**6;
//     //     uint256 amountInSwap = 1850*10**6;
//     //     uint256 amountOutSwap = 1*10**18;

//     //     assertEq(ARB_USDC_MAINNET.balanceOf(address(s_uniSwapWrapper)), 0);
//     //     assertEq(ARB_WETH_MAINNET.balanceOf(address(s_uniSwapWrapper)), 0);

//     //     assertEq(ARB_USDC_MAINNET.balanceOf(address(s_multiSig)), 0);

//     //     IStartSwapFacet.DexPayload memory dexPayload = IStartSwapFacet.DexPayload({
//     //         path: path,
//     //         amountInForInputToken: amountInSwap,
//     //         deadline: block.timestamp + 60
//     //     });

//     //     INonFungiblePositionManager.MintParams memory stakePayload = INonFungiblePositionManager.MintParams({
//     //         token0: address(ARB_USDC_MAINNET),
//     //         token1: address(ARB_WETH_MAINNET),
//     //         fee: USDC_WETH_POOL_FEE,
//     //         tickLower: MIN_TICK,
//     //         tickUpper: MAX_TICK,
//     //         amount0Desired: amountInSwap,
//     //         amount1Desired: amountOutSwap,
//     //         amount0Min: 0,
//     //         amount1Min: 0,
//     //         recipient: s_user02,
//     //         deadline: block.timestamp + 60
//     //     });

//     //     vm.startPrank(s_user02);
//     //     ARB_USDC_MAINNET.approve(address(s_uniSwapWrapperArb), totalAmountIn);
//     //     s_uniSwapWrapperArb.startSwap(totalAmountIn, dexPayload, stakePayload);
//     //     vm.stopPrank();

//     //     ///Ensure the Multisig receives the protocol fee
//     //     assertGt(ARB_USDC_MAINNET.balanceOf(address(s_multiSig)), (amountInSwap / 50));
//     //     assertGt(ARB_WETH_MAINNET.balanceOf(address(s_multiSig)), (amountOutSwap / 50));
//     //     ///Ensure protocol doesn't hold any asset
//     //     assertEq(ARB_USDC_MAINNET.balanceOf(address(s_uniSwapWrapperArb)), 0);
//     //     assertEq(ARB_WETH_MAINNET.balanceOf(address(s_uniSwapWrapperArb)), 0);
//     // }
// }