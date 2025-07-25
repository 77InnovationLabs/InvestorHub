///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*/////////////////////////////
            Imports
/////////////////////////////*/
import { PoolKey } from "@uniswap/v4-core/src/types/PoolKey.sol";

/*/////////////////////////////
            Interfaces
/////////////////////////////*/
import { INonFungiblePositionManager } from "src/interfaces/UniswapV3/INonFungiblePositionManager.sol";
import { IUniversalRouter } from "@uniswap/universal-router/contracts/interfaces/IUniversalRouter.sol";
import { IAllowanceTransfer } from "@uniswap/permit2/src/interfaces/IAllowanceTransfer.sol";

/*/////////////////////////////
            Libraries
/////////////////////////////*/


interface IStartPositionFacet {

    /*///////////////////////////////////
            Type Declarations
    ///////////////////////////////////*/
    struct SwapPayload {
        bytes commands;
        bytes actions;
        bytes functionData;
        bytes tokenIn;
        bytes tokenOut;
    }


    /*///////////////////////////////////
                Events
    ///////////////////////////////////*/
    ///@notice event emitted when a new position is opened.
    event StartUniswapV3PositionFacet_PositionStarted(uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    /*///////////////////////////////////
                Errors
    ///////////////////////////////////*/
    ///@notice error emitted when the call is not a delegatecall
    error StartUniswapV3PositionFacet_CallerIsNotDiamond(address context, address diamond);
    ///@notice error emitted if one of the amounts to stake is zero
    error StartUniswapV3PositionFacet_InvalidAmountToInvest(uint256 amount0Desired, uint256 amount1Desired);
    ///@notice error emitted when the payload size is greater than the maximum allowed
    error StartUniswapV3PositionFacet_InvalidPayloadSize();
    ///@notice error emitted when the amount to invest is insufficient
    error StartUniswapV3PositionFacet_InsufficientAmountToInvest(uint256 amount);

    /*///////////////////////////////////
                Functions
    ///////////////////////////////////*/
    
    function startPosition(
        INonFungiblePositionManager.MintParams memory _params, 
        IAllowanceTransfer.PermitBatch calldata _permitSingle,
        bytes calldata _signature,
        PoolKey[] calldata _key, 
        SwapPayload[] memory _swapPayload, 
        uint48 _deadline
    ) external;
}