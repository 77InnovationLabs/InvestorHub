// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { console } from "forge-std/Console.sol";

///Test Helper
import { ForkedHelper } from "test/helpers/ForkedHelper.t.sol";

///Protocol Interfaces
import { ICCIPFacets } from "src/interfaces/Chainlink/ICCIPFacets.sol";
import { IStartSwapFacet } from "src/interfaces/UniswapV3/IStartSwapFacet.sol";
import { INonFungiblePositionManager } from "src/interfaces/UniswapV3/IStartPositionFacet.sol";

///Chainlink Tools
import { Client } from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";

contract CrossChainSwap is ForkedHelper {

    function test_startCrossChainInvestment() external baseMainnetMod{
        uint256 totalAmountIn = 1e18;
        uint256 totalMinAmountOut = 3_500e6;
        
        vm.startPrank(user02);
        BASE_WETH_MAINNET.approve(d, totalAmountIn);

        ICCIPFacets(d).startCrossChainInvestment(
            _generateLocalSwapPayload(totalAmountIn, totalMinAmountOut),
            _generateCompleteCCPayload(totalMinAmountOut)
        );

        ccipLocal.switchChainAndRouteMessage(arbMainnet);

        vm.stopPrank();
    }

    function _generateLocalSwapPayload(uint256 _totalAmountIn, uint256 _totalMinAmountOut) internal pure returns(ICCIPFacets.SwapPayload memory payload_){
        bytes memory path0 = abi.encodePacked(BASE_WETH_ADDRESS, BASE_USDC_WETH_POOL_FEE, BASE_USDC_ADDRESS);
        
        payload_ = ICCIPFacets.SwapPayload({
            path: path0,
            inputToken: BASE_WETH_ADDRESS,
            deadline: 0,
            totalAmountIn: _totalAmountIn,
            minAmountOut: _totalMinAmountOut
        });
    }

    function _generateCompleteCCPayload(uint256 _totalMinAmountOut) internal view returns(ICCIPFacets.CCPayload memory payload_){
        payload_ = ICCIPFacets.CCPayload ({
            transaction: _generateTransactionData(_totalMinAmountOut),
            swaps: _generateCCSwapPayload(_totalMinAmountOut),
            investment: _generateInvestmentPayload()
        });
    }

    function _generateTransactionData(uint256 _totalMinAmountOut) internal view returns(ICCIPFacets.TransactionData memory tx_){
        tx_ = ICCIPFacets.TransactionData({
            chainSelector: ARB_CHAIN_SELECTOR,
            receiverContract: dArb,
            amountToSend: _totalMinAmountOut,
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV2({
                    gasLimit: CCIP_GAS_LIMIT,
                    allowOutOfOrderExecution: true
                })
            )
        });
    }

    function _generateCCSwapPayload(uint256 _totalMinAmountOut) internal view returns(ICCIPFacets.SwapPayload[2] memory payload_){
        uint256 totalAmountIn0 = _totalMinAmountOut / 2;
        uint256 totalAmountIn1 = _totalMinAmountOut / 2;
        uint256 minAmountOut0 = 0.41 ether;
        uint256 minAmountOut1 = 3_300e18;

        uint256 deadline= block.timestamp + 60;
        bytes memory path0 = abi.encodePacked(ARB_USDC_ADDRESS, ARB_USDC_WETH_POOL_FEE, ARB_WETH_ADDRESS);
        bytes memory path1 = abi.encodePacked(ARB_USDC_ADDRESS, ARB_WETH_ARB_POOL_FEE, ARB_ARB_ADDRESS);
        
        payload_[0] = ICCIPFacets.SwapPayload({
            path: path0,
            inputToken: ARB_USDC_ADDRESS,
            deadline: deadline,
            totalAmountIn: totalAmountIn0,
            minAmountOut: minAmountOut0
        });

        payload_[1] = ICCIPFacets.SwapPayload({
            path: path1,
            inputToken: ARB_USDC_ADDRESS,
            deadline: deadline,
            totalAmountIn: totalAmountIn1,
            minAmountOut: minAmountOut1
        });

    }

    function _generateInvestmentPayload() internal view returns(ICCIPFacets.CCInvestment memory inv_){
        uint256 minAmountOut0 = 15e17;
        uint256 minAmountOut1 = 18_000e18;

        inv_ = ICCIPFacets.CCInvestment({
            investmentTarget: ICCIPFacets.SupportedTarget.UniswapV3,
            token0: ARB_WETH_ADDRESS,
            token1: ARB_ARB_ADDRESS,
            fee: ARB_WETH_ARB_POOL_FEE,
            tickLower: -887270,//_findNearestValidTick(true, ARB_WETH_ADDRESS, ARB_ARB_ADDRESS, ARB_WETH_ARB_POOL_FEE),
            tickUpper: 887270, //_findNearestValidTick(false, ARB_WETH_ADDRESS, ARB_ARB_ADDRESS, ARB_WETH_ARB_POOL_FEE),
            amount0Desired: minAmountOut0,
            amount1Desired: minAmountOut1,
            amount0Min: _calculateSlippage(minAmountOut0),
            amount1Min: _calculateSlippage(minAmountOut1),
            recipient: user02,
            deadline: block.timestamp + 60
        });
    }
}