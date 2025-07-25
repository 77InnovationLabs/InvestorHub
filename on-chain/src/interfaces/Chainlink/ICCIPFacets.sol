///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface ICCIPFacets {

    /*/////////////////////////////////////////////
                    Type Declarations
    /////////////////////////////////////////////*/
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

    /*/////////////////////////////////////////////
                        Events
    /////////////////////////////////////////////*/
    ///@notice event emitted when a CCIP transaction is successfully sent
    event CCIPSendFacet_MessageSent(bytes32 txId, uint64 destinationChainSelector, address sender, uint256 fees);

    /*/////////////////////////////////////////////
                        Error
    /////////////////////////////////////////////*/
    ///@notice error emitted when the function is not executed in the Diamond context
    error CCIPSendFacet_CallerIsNotDiamond(address actualContext, address diamondContext);
    ///@notice error emitted when the tokenOut of a local swap is not USDC
    error CCIPSendFacet_InvalidLocalSwapInput();
    ///@notice error emitted when the link balance is not enough
    error CCIPSendFacet_NotEnoughBalance(uint256 fees, uint256 linkBalance);

    /*/////////////////////////////////////////////
                    Functions
    /////////////////////////////////////////////*/
    function startCrossChainInvestment(
        SwapPayload memory _swapPayload,
        CCPayload memory _payload
    ) external;
}