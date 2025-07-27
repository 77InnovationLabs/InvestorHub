///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*/////////////////////////////
            Imports
/////////////////////////////*/

/*/////////////////////////////
            Interfaces
/////////////////////////////*/
import { INonFungiblePositionManager } from "src/interfaces/UniswapV3/INonFungiblePositionManager.sol";
import { IPermit2 } from "@uniswap/permit2/src/interfaces/IPermit2.sol";

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
    event StartPositionFacet_PositionStarted(uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    /*///////////////////////////////////
                Errors
    ///////////////////////////////////*/
    ///@notice error emitted when the call is not a delegatecall
    error StartPositionFacet_CallerIsNotDiamond(address context, address diamond);
    ///@notice error emitted if one of the amounts to stake is zero
    error StartPositionFacet_InvalidAmountToInvest(uint256 amount0Desired, uint256 amount1Desired);
    ///@notice error emitted when the payload size is greater than the maximum allowed
    error StartPositionFacet_InvalidPayloadSize();
    ///@notice error emitted when the amount to invest is insufficient
    error StartPositionFacet_InsufficientAmountToInvest(uint256 amount);
    ///@notice error emitted when the swapPayload array is bigger than the number of tokens received
    error StartPositionFacet_SwapPayloadCantBeBiggerThanTheNumberOfTokensReceived();

    /*///////////////////////////////////
                Functions
    ///////////////////////////////////*/
    
    function startPosition(
        INonFungiblePositionManager.MintParams memory _params, 
        IPermit2.PermitBatch calldata _permitBatch,
        bytes calldata _signature,
        IPermit2.AllowanceTransferDetails[] memory _transfer,
        SwapPayload[] memory _swapPayload, 
        uint48 _deadline
    ) external;
}