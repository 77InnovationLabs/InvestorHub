// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { console } from "forge-std/Console.sol";

///Test Helper
import { ForkedHelper } from "test/helpers/ForkedHelper.t.sol";

///Protocol Interfaces
import { IStartPositionFacet, INonFungiblePositionManager } from "src/interfaces/UniswapV3/IStartPositionFacet.sol";

//Uniswap
import { IAllowanceTransfer } from "@uniswap/permit2/src/interfaces/IAllowanceTransfer.sol";

contract StartPositionFunctionTest is ForkedHelper {

    /**
        @notice Function to test if a user with one of the token's pool
        successfully executes a single swap and initiate a position
    */
    function test_oneSwapToPool() public baseMainnetMod {

        /*/////////////////////////////////////////////////
                            PAYLOAD DATA
        /////////////////////////////////////////////////*/
        bytes memory path = abi.encodePacked(BASE_USDC_ADDRESS, BASE_USDC_WETH_POOL_FEE, BASE_WETH_ADDRESS);
        uint256 totalAmountIn = 6000e6;
        uint256 amountInSwap = 3000e6;
        uint256 amountOutSwap = 0.83 ether;

        /*/////////////////////////////////////////////////
                        INVESTMENT PAYLOAD
        /////////////////////////////////////////////////*/
        INonFungiblePositionManager.MintParams memory investPayload = INonFungiblePositionManager.MintParams({
            token0: BASE_USDC_ADDRESS,
            token1: BASE_WETH_ADDRESS,
            fee: BASE_USDC_WETH_POOL_FEE,
            tickLower: _findNearestValidTick(true, BASE_USDC_ADDRESS, BASE_WETH_ADDRESS, BASE_USDC_WETH_POOL_FEE),
            tickUpper: _findNearestValidTick(false, BASE_USDC_ADDRESS, BASE_WETH_ADDRESS, BASE_USDC_WETH_POOL_FEE),
            amount0Desired: amountInSwap,
            amount1Desired: amountOutSwap,
            amount0Min: _calculateSlippage(amountInSwap),
            amount1Min: _calculateSlippage(amountOutSwap),
            recipient: user02,
            deadline: block.timestamp + DEADLINE
        });

        /*/////////////////////////////////////////////////
                            SWAP PAYLOAD
        /////////////////////////////////////////////////*/
        IStartPositionFacet.SwapPayload[] memory swapPayload = new IStartPositionFacet.SwapPayload[](2);
        // swapPayload[0] = _generateSwapPayload(
        //     abi.encode(token0, amountIn),  //tokenIn
        //     abi.encode(token1, amountOut) //tokenOut
        //     path,
        //     d, //This must be enforced on-chain. We need to ensure the receiver is the contract.
        //     amountIn,
        //     amountOutMinimum
        // );
        // swapPayload[1] = _generateSwapPayload(
        //     abi.encode(token0, amountIn),  //tokenIn
        //     abi.encode(token1, amountOut), //tokenOut
        //     path,
        //     d, //This must be enforced on-chain. We need to ensure the receiver is the contract.
        //     amountIn,
        //     amountOutMinimum
        // );

        /*/////////////////////////////////////////////////
                            PRE VALIDATIONS
        /////////////////////////////////////////////////*/
        //Diamond
        uint256 diamondUsdcBalanceBefore = BASE_USDC_MAINNET.balanceOf(d);
        uint256 diamondWEthBalanceBefore = BASE_WETH_MAINNET.balanceOf(d);
        //MultiSig
        uint256 msUsdcBalanceBefore = BASE_USDC_MAINNET.balanceOf(multisig);
        uint256 msWEthBalanceBefore = BASE_WETH_MAINNET.balanceOf(multisig);
        //User
        uint256 userUsdcBalanceBefore = BASE_USDC_MAINNET.balanceOf(user02);
        uint256 userWEthBalanceBefore = BASE_WETH_MAINNET.balanceOf(user02);

        /*/////////////////////////////////////////////////
                        TRANSACTION EXECUTION
        /////////////////////////////////////////////////*/
        vm.startPrank(user02);
        // position.startPosition(
        //     investPayload, 
        //     permit2,
        //     signature,
        //     transferDetails
        //     swapPayload, 
        //     DEADLINE
        // );
        vm.stopPrank();

        /*/////////////////////////////////////////////////
                            POST VALIDATIONS
        /////////////////////////////////////////////////*/
        ///Ensure the Multisig receives the protocol fee
        assertEq(BASE_USDC_MAINNET.balanceOf(multisig), msUsdcBalanceBefore + (amountInSwap / BPS_FEE));
        assertGt(BASE_WETH_MAINNET.balanceOf(multisig), msWEthBalanceBefore + (amountOutSwap / BPS_FEE));
        ///Ensure protocol doesn't hold any asset
        assertEq(BASE_USDC_MAINNET.balanceOf(d), diamondUsdcBalanceBefore);
        assertEq(BASE_WETH_MAINNET.balanceOf(d), diamondWEthBalanceBefore);
        ///Validate user balance
        assertGt(BASE_USDC_MAINNET.balanceOf(user02), userUsdcBalanceBefore - totalAmountIn);
        assertGt(BASE_WETH_MAINNET.balanceOf(user02), userWEthBalanceBefore);
        //Validate if the user receives the NFT
        assertEq(nft.ownerOf(3_556_073), user02);
    }

    /**
        @notice Function to test if a user with none of the token's pool
        successfully exchange a third token into both of the token's pool
        and initialize a position
    */
    // function test_noneTokenSwapToPoolsTokens() public baseMainnetMod {

    //     /*/////////////////////////////////////////////////
    //                     PAYLOAD INITIALIZATION
    //     /////////////////////////////////////////////////*/
    //     uint256 totalAmountIn = 6000e6;
    //     uint256 amountInSwap = 3000e6;
    //     uint256 amountOutSwap0 = 0.83 ether;
    //     uint256 amountOutSwap1 = 3.250 ether;

    //     bytes memory path0 = abi.encodePacked(BASE_USDC_ADDRESS, BASE_USDC_WETH_POOL_FEE, BASE_WETH_ADDRESS);
    //     bytes memory path1 = abi.encodePacked(BASE_USDC_ADDRESS, BASE_USDC_AERO_POOL_FEE, BASE_AERO_ADDRESS);

    //     IStartSwapFacet.DexPayload[] memory dexPayload = new IStartSwapFacet.DexPayload[](2);

    //     dexPayload[0] = IStartSwapFacet.DexPayload({
    //         path: path0,
    //         amountInForInputToken: amountInSwap,
    //         deadline: 0
    //     });

    //     dexPayload[1] = IStartSwapFacet.DexPayload({
    //         path: path1,
    //         amountInForInputToken: amountInSwap,
    //         deadline: 0
    //     });

    //     INonFungiblePositionManager.MintParams memory stakePayload = INonFungiblePositionManager.MintParams({
    //         token0: BASE_WETH_ADDRESS,
    //         token1: BASE_AERO_ADDRESS,
    //         fee: BASE_WETH_AERO_POOL_FEE,
    //         tickLower: _findNearestValidTick(true, BASE_WETH_ADDRESS, BASE_AERO_ADDRESS, BASE_WETH_AERO_POOL_FEE),
    //         tickUpper: _findNearestValidTick(false, BASE_WETH_ADDRESS, BASE_AERO_ADDRESS, BASE_WETH_AERO_POOL_FEE),
    //         amount0Desired: amountOutSwap0,
    //         amount1Desired: amountOutSwap1,
    //         amount0Min: _calculateSlippage(amountOutSwap0),
    //         amount1Min: _calculateSlippage(amountOutSwap1),
    //         recipient: user02,
    //         deadline: block.timestamp + DEADLINE
    //     });

    //     /*/////////////////////////////////////////////////
    //                         PRE VALIDATIONS
    //     /////////////////////////////////////////////////*/

    //     /*/////////////////////////////////////////////////
    //                     TRANSACTION EXECUTION
    //     /////////////////////////////////////////////////*/
    //     vm.startPrank(user02);
    //     BASE_USDC_MAINNET.approve(d, totalAmountIn);
    //     swap.startSwap(BASE_USDC_ADDRESS, totalAmountIn, dexPayload, stakePayload);
    //     vm.stopPrank();

    //     /*/////////////////////////////////////////////////
    //                         POST VALIDATIONS
    //     /////////////////////////////////////////////////*/

    //     //Validate if the user receives the NFT
    //     // assertEq(nft.ownerOf(2935624), user02);
    // }
}