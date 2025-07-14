// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*///////////////////////////////////
            Imports
///////////////////////////////////*/
// import {AppStorage} from "src/storage/AppStorage.sol"; unused

/*///////////////////////////////////
            Interfaces
///////////////////////////////////*/
import { IStartSwapFacet } from "src/interfaces/UniswapV3/IStartSwapFacet.sol";
import { IStartPositionFacet, INonFungiblePositionManager } from "src/interfaces/UniswapV3/IStartPositionFacet.sol";

/*///////////////////////////////////
            Libraries
///////////////////////////////////*/
import {LibTransfers} from "src/libraries/LibTransfers.sol";
import {LibUniswapV3} from "src/libraries/LibUniswapV3.sol";

/**
    *@title StartSwapFacet - Diamond Uniswap Facet
    *@notice Contract Designed to Swap and trigger the stake for users investments on UniswapV3
*/
contract StartSwapFacet {

    /*///////////////////////////////////
                    Variables
    ///////////////////////////////////*/
    ///@notice immutable variable to store the diamond address
    address immutable i_diamond;
    ///@notice immutable variable to store the router address
    address immutable i_router;

    ///@notice constant variable to store MAGIC NUMBERS
    uint8 private constant ZERO = 0;

    /*///////////////////////////////////
                    Events
    ///////////////////////////////////*/

    /*///////////////////////////////////
                    Errors
    ///////////////////////////////////*/
    ///@notice error emitted when the function is not executed in the Diamond context
    error StartSwapFacet_CallerIsNotDiamond(address actualContext, address diamondContext);
    ///@notice error emitted when the liquidAmount is zero
    error StartSwapFacet_InvalidAmountToSwap(uint256 amountIn);
    ///@notice error emitted when the first token of a swap is the address(0)
    error StartSwapFacet_InvalidToken0(address tokenIn);
    ///@notice error emitted when the last token != than the token to stake
    error StartSwapFacet_InvalidToken1(address tokenOut);
    ///@notice error emitted when the amount of token0 left is less than the amount needed to stake
    error StartSwapFacet_InvalidProportion();

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
        *@notice external function to handle the creation of an investment position
        *@param _payload the data to perform swaps
        *@param _stakePayload the data to perform the stake operation
        *@dev this function must be able to perform swaps and stake the tokens
        *@dev the stToken must be sent directly to user.
        *@dev the _stakePayload must contain the final value to be deposited, the calculations
    */
    function startSwap(
        uint256 _totalAmountIn,
        IStartSwapFacet.DexPayload memory _payload,
        INonFungiblePositionManager.MintParams memory _stakePayload
    ) external {
        if(address(this) != i_diamond) revert StartSwapFacet_CallerIsNotDiamond(address(this), i_diamond);
        if(_totalAmountIn == ZERO) revert StartSwapFacet_InvalidAmountToSwap(_totalAmountIn);

        // retrieve tokens from UniV3 path input
        (
            address token0,
            address token1
        ) = LibUniswapV3._extractTokens(_payload.path);

        //TODO: Sanity checks
        if(token0 != _stakePayload.token0) revert StartSwapFacet_InvalidToken0(token0);
        if(token1 != _stakePayload.token1) revert StartSwapFacet_InvalidToken1(token1);
        if(_totalAmountIn - _payload.amountInForInputToken < _stakePayload.amount0Desired) revert StartSwapFacet_InvalidProportion();
        
        _totalAmountIn = LibTransfers._handleTokenTransfers(token0, _totalAmountIn);

        (
            _stakePayload.amount0Desired, //Update the values to be staked
            _stakePayload.amount1Desired // with the dust and amount received from the swap
        )= LibUniswapV3._handleSwap(
            i_router,
            _payload.path,
            token0,
            _payload.deadline,
            _payload.amountInForInputToken, ///@dev the input is only the amount necessary to perform the swap and receive the token1 amount to stake
            _stakePayload.amount1Desired ///@dev User has Token0 and is Swapping for Token1. So, the minAmountOut is the amount1Desired to invest.
        );

        _stakePayload = normalizeStakePayload(_stakePayload);

        //Delegatecall to an internal facet to process the stake
        //question Do we need the values returned?
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

    /*///////////////////////////////////
                    Private
    ///////////////////////////////////*/

    /**
     * @notice Normalizes the token order within a Uniswap V3 `MintParams` struct to adhere to Uniswap's requirements.
     * @dev Uniswap V3 requires `token0` to have a lower address value than `token1`. 
     *      This function ensures the tokens are correctly ordered and swaps the corresponding amounts if necessary.
     * @param _stakePayload The `MintParams` struct containing the parameters for minting a Uniswap V3 position.
     * @return The normalized `MintParams` struct with tokens and corresponding amounts correctly ordered.
     *
     * @dev If `token0` is greater than `token1`, the function will:
     *      - Swap `token0` and `token1`
     *      - Swap `amount0Desired` and `amount1Desired`
     *      - Swap `amount0Min` and `amount1Min`
     *
     * @dev This ensures compatibility with the Uniswap V3 `mint()` function, which expects token0 < token1.
     */
    function normalizeStakePayload(INonFungiblePositionManager.MintParams memory _stakePayload) private pure returns (INonFungiblePositionManager.MintParams memory) {
        //TODO: analyze the possibility to do it off-chain
        if (_stakePayload.token0 > _stakePayload.token1) {
            (_stakePayload.token0, _stakePayload.token1) = (_stakePayload.token1, _stakePayload.token0);
            (_stakePayload.amount0Desired, _stakePayload.amount1Desired) = (_stakePayload.amount1Desired, _stakePayload.amount0Desired);
            (_stakePayload.amount0Min, _stakePayload.amount1Min) = (_stakePayload.amount1Min, _stakePayload.amount0Min);
        }
        return _stakePayload;
    }
}