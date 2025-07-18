///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface ICCIPFacets {

    struct SwapPayload{
        bytes path;
        address inputToken;
        uint256 deadline;
        uint256 totalAmountIn;
        uint256 minAmountOut;
    }

    struct CCInvestment{
        SupportedTarget investmentTarget;
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct TransactionData{
        uint64 chainSelector;
        address receiverContract;
        uint256 amountToSend;
        bytes extraArgs;
    }

    struct CCPayload{
        TransactionData transaction;
        SwapPayload[2] swaps;
        CCInvestment investment;
    }

    enum SupportedTarget{
        UniswapV3,
        AaveV3, //Not Supported Yet, just for testing
        CompoundV3 //Not Supported Yet, just for testing
    }

    function startCrossChainInvestment(
        SwapPayload memory _uniswapV3Payload,
        CCPayload memory _payload
    ) external;
}