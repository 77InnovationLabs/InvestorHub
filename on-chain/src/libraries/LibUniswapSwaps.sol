//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*///////////////////////////////////
            Imports
///////////////////////////////////*/
import { IUniversalRouter } from "@uniswap/universal-router/contracts/interfaces/IUniversalRouter.sol";
import { Currency } from "@uniswap/v4-core/src/types/Currency.sol";

/*/////////////////////////////
            Interfaces
/////////////////////////////*/
import { IAllowanceTransfer } from "@uniswap/permit2/src/interfaces/IAllowanceTransfer.sol";
import { IStartPositionFacet } from "src/interfaces/UniswapV3/IStartPositionFacet.sol";

/*/////////////////////////////
            Libraries
/////////////////////////////*/
import { Bytes } from "@openzeppelin/contracts/utils/Bytes.sol";
import { Commands } from "@uniswap/universal-router/contracts/libraries/Commands.sol";

library LibUniswapSwaps{

    /*///////////////////////////////////
             Type declarations
    ///////////////////////////////////*/
    using Bytes for bytes;

    /*/////////////////////////////////////////////
                    State Variables
    /////////////////////////////////////////////*/
    ///@notice constant variable to store MAGIC NUMBERS
    uint8 private constant ZERO = 0;

    /*///////////////////////////////////
                Errors
    ///////////////////////////////////*/

    ////////////////////////////////////////////////////////////////////////////////
                                /// Functions ///
    ////////////////////////////////////////////////////////////////////////////////

    /**
        *@notice Private function to handle swaps. It allows to simplify `startPosition` logic and avoid duplicated code
        *@param _router the address of the Uniswap UniversalRouter
        *@param _permitBatch the permit to transfer tokens on behalf of the user
        *@param _signature the signature to verify the permit
        *@param _swapPayload the payload to perform swaps
        *@param _deadline the deadline for the swap
    */
    function _handleSwap(
        address _router,
        IAllowanceTransfer.PermitBatch calldata _permitBatch,
        bytes calldata _signature,
        IStartPositionFacet.SwapPayload[] memory _swapPayload,
        uint48 _deadline
    ) internal {
        uint256 payloadLength = _swapPayload.length;

        // Create the commands for the swap. Start with the PERMIT2_TRANSFER_FROM_BATCH command
        bytes memory commands = abi.encodePacked(uint8(Commands.PERMIT2_TRANSFER_FROM_BATCH));

        // Create the inputs for the swap
        bytes[] memory inputs = new bytes[](payloadLength + 1);
        // Add the PERMIT2_PERMIT command at the inputs' first position
        inputs[0] = abi.encode(_permitBatch, _signature);

        // Iterate over the payloads and create the commands and inputs
        for(uint256 i; i < payloadLength; ++i) {
            commands = bytes.concat(commands, _swapPayload[i].commands);

            bytes[] memory params = new bytes[](3);
            params[0] = _swapPayload[i].functionData;
            params[1] = _swapPayload[i].tokenIn;
            params[2] = _swapPayload[i].tokenOut;

            inputs[i + 1] = abi.encode(_swapPayload[i].actions, params);
        }

        // This is what is called inside of the UniversalRouter
        //  else if (command == Commands.PERMIT2_PERMIT_BATCH) {
        //       (IAllowanceTransfer.PermitBatch memory permitBatch,) =
        //           abi.decode(inputs, (IAllowanceTransfer.PermitBatch, bytes));
        //       bytes calldata data = inputs.toBytes(1);
        //       PERMIT2.permit(lockedBy, permitBatch, data);
        //  }
        IUniversalRouter(_router).execute(commands, inputs, _deadline);
    }
}