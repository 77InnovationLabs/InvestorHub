//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*///////////////////////////////////
            Imports
///////////////////////////////////*/

/*///////////////////////////////////
            Interfaces
///////////////////////////////////*/
import { IStartSwapFacet } from "src/interfaces/UniswapV3/IStartSwapFacet.sol";
import { IStartPositionFacet, INonFungiblePositionManager } from "src/interfaces/UniswapV3/IStartPositionFacet.sol";

/*///////////////////////////////////
            Libraries
///////////////////////////////////*/
import { LibTransfers } from "src/libraries/LibTransfers.sol";
import { LibUniswapV3 } from "src/libraries/LibUniswapV3.sol";

/**
    *@title Swap & Stake - Diamond Uniswap Facet
    *@notice Contract Designed to Swap and Stake users investments on UniswapV3
*/
contract StartFullSwapFacet {

    /*///////////////////////////////////
              State Variables
    ///////////////////////////////////*/
    ///@notice immutable variable to store the diamond address
    address immutable i_diamond;
    ///@notice immutable variable to store the router address
    address immutable i_router;

    ///@notice constant variable to store MAGIC NUMBERS
    uint8 private constant ZERO = 0;
    ///@notice the number of items that will be processed on the swap function
    uint8 constant TWO = 2;

    /*///////////////////////////////////
                    Events
    ///////////////////////////////////*/

    /*///////////////////////////////////
                    Errors
    ///////////////////////////////////*/
    ///@notice error emitted when the function is not executed in the Diamond context
    error StartFullSwapFacet_CallerIsNotDiamond(address actualContext, address diamondContext);
    ///@notice error emitted when the liquidAmount is zero
    error StartFullSwapFacet_InvalidAmountToSwap(uint256 amountIn, uint256 expectedAmount);
    ///@notice error emitted when the payload is bigger than allowed
    error StartFullSwapFacet_InvalidSwapPayload(uint256 payloadSize);
    ///@notice error emitted when the input array is to big
    error StartFullSwapFacet_ArrayBiggerThanTheAllowedSize(uint256 arraySize);
    ///@notice error emitted when the staking payload sent is different than the validated struct
    error StartFullSwapFacet_InvalidStakePayload(bytes32 hashOfEncodedPayload, bytes32 hashOfStructArgs);
    ///@notice error emitted when a delegatecall fails
    error StartFullSwapFacet_UnableToDelegatecall(bytes data);
    ///@notice error emitted when the swap input token is different than the received token
    error StartFullSwapFacet_InvalidInputToken(address receivedToken0, address inputToken0);
    ///@notice error emitted when the first token of a swap is the address(0)
    error StartFullSwapFacet_InvalidOutputToken(address swapOutput, address stakeInput);
    ///@notice error emitted when the amount of token0 left is less than the amount needed to stake
    error StartFullSwapFacet_InvalidProportion();

    /*///////////////////////////////////
                    Functions
    ///////////////////////////////////*/
    
    ///@notice Facet constructor
    constructor(address _diamond, address _router){
        i_diamond = _diamond;
        i_router = _router;
        //never update state variables inside
    }

    /*///////////////////////////////////
                  External
    ///////////////////////////////////*/
    /**
        *@notice external start the full cycle to create an investment position
        *@notice this function receives a Token A and swaps it for Token X & Token Z
        *@notice these tokens are then deposited on a UniswapV3 pool
        *@param _payload the data to perform swaps
        *@param _stakePayload the data to perform the stake operation
        *@dev this function must be able to perform swaps and stake the tokens
        *@dev the stToken must be sent directly to user.
        *@dev the _stakePayload must contain the final value to be deposited, the calculations
    */
    function startSwap(
        address _inputToken,
        uint256 _totalAmountIn,
        IStartSwapFacet.DexPayload[] memory _payload,
        INonFungiblePositionManager.MintParams memory _stakePayload
    ) external {
        if(address(this) != i_diamond) revert StartFullSwapFacet_CallerIsNotDiamond(address(this), i_diamond);
        uint256 totalAmountInForIterations = _payload[0].amountInForInputToken + _payload[1].amountInForInputToken;
        if(_totalAmountIn < totalAmountInForIterations) revert StartFullSwapFacet_InvalidAmountToSwap(_totalAmountIn, totalAmountInForIterations);
        if(_payload.length != TWO) revert StartFullSwapFacet_InvalidSwapPayload(_payload.length);

        _totalAmountIn = LibTransfers._handleTokenTransfers(_inputToken, _totalAmountIn);

        uint256 remainingValueOfInputToken;
        uint256 amountReceiveOfOutputToken;

        for(uint256 i = 0; i < TWO ; ++i){
            // retrieve tokens from UniV3 path input
            (
                address token0,
                address token1
            ) = LibUniswapV3._extractTokens(_payload[i].path);

            ///accounts for a specific token according to the iteration
            ///always looking for the output for each iteration,
            ///as the input token will always be the same in this scenario.
            address tokenOut = i == ZERO ? _stakePayload.token0 : _stakePayload.token1;

            /// checks if the input token is the token received.
            if(_inputToken != token0 ) revert StartFullSwapFacet_InvalidInputToken(_inputToken, token0);
            /// checks if the token out correspond to the correct token to be staked
            if(token1 != tokenOut) revert StartFullSwapFacet_InvalidOutputToken(token1, tokenOut);
            
            ///_handleSwapsV3 returns the amount left of the inputToken. So,
            ///the most important, in this particular process,
            ///is to override the tokenIn amount after the first swap.
            ///this way we can use a bigger amount for the second swap.
            ///And yes, we will not update the slippage.
            ///Users can see, on our interface, the min amount they will receive
            ///Once accepted, before tx initiation, they are ok with any outcome bigger than that.
            //QUESTION: Sanity checks?!
            //QUESTION: can we make it more efficient and straightforward?
            uint256 amountExpectedFromOutputToken = i == ZERO ? _stakePayload.amount0Desired : _stakePayload.amount1Desired;
            (
                remainingValueOfInputToken,
                amountReceiveOfOutputToken
            )= LibUniswapV3._handleSwap(
                i_router,
                _payload[i].path,
                _inputToken,
                _payload[i].deadline,
                _payload[i].amountInForInputToken,
                amountExpectedFromOutputToken
            );

            if(i == ZERO){
                _payload[i + 1].amountInForInputToken = remainingValueOfInputToken;
                _stakePayload.amount0Desired = amountReceiveOfOutputToken;
            } else {
                _stakePayload.amount1Desired = amountReceiveOfOutputToken;
            }
        }

        // Delegatecall to an internal facet to process the stake
        LibTransfers._handleDelegateCalls(
            i_diamond,
            abi.encodeWithSelector(
                IStartPositionFacet.startPositionUniswapV3.selector,
                _stakePayload,
                true,
                false
            )
        );
    }

}