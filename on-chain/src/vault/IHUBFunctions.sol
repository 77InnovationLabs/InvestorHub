///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*/////////////////////////////
            Imports
/////////////////////////////*/
import { VaultAutomationStorage } from "src/vault/storage/VaultAutomationStorage.sol";
import { FunctionsClient } from "@chainlink/contracts/src/v0.8/functions/dev/v1_X/FunctionsClient.sol";

/*/////////////////////////////
            Libraries
/////////////////////////////*/
import { FunctionsRequest } from "@chainlink/contracts/src/v0.8/functions/dev/v1_X/libraries/FunctionsRequest.sol";
import { LibUniswapSwaps } from "src/libraries/LibUniswapSwaps.sol";

abstract contract IHUBFunctions is FunctionsClient, VaultAutomationStorage {
    /*/////////////////////////////////////////////
                    Type Declarations
    /////////////////////////////////////////////*/
    using FunctionsRequest for FunctionsRequest.Request;

    /*///////////////////////////////////
                Variables
    ///////////////////////////////////*/

    ///@notice Chainlink Functions donId for the specific chain.
    bytes32 immutable i_donId;
    ///@notice Chainlink Subscription ID to process requests
    uint64 immutable i_subscriptionId;

    ///@notice the amount of gas needed to complete the call
    uint32 constant CALLBACK_GAS_LIMIT = 200_000;
    ///@notice Constant variable to hold the JS Script to be executed off-chain.
    string constant SOURCE_CODE = '';
    ///@notice constant variable to store MAGIC NUMBERS
    uint8 private constant ZERO = 0;

    ///@notice event emitted when a functions request is triggered
    event IHUBFunctions_FunctionsRequestSent(bytes32 requestId);
    ///@notice event emitted when the functions flow succeed
    event IHUBFunctions_CallbackReceivedAndSwapSucceed(bytes32 requestId);
    ///@notice event emitted when the callback fails
    event IHUBFunctions_RequestFailed(bytes32 requestId, bytes err);

    ///@notice error emitted when the callback requests was already fulfilled
    error IHUBFunctions_RequestAlreadyFulfilled(bytes32 requestId);

    /*///////////////////////////////////
                constructor
    ///////////////////////////////////*/
    constructor(
        address _router, 
        bytes32 _donId, 
        uint64 _subscriptionId,
        address _owner
    ) FunctionsClient(_router) VaultAutomationStorage(_owner){
        i_donId = _donId;
        i_subscriptionId = _subscriptionId;
    }

    /*//////////////////////////////
                Internal
    //////////////////////////////*/
    /**
     * @notice Function to initiate a CLF simple request and query the eth balance of a address
     * @param _bytesArgs Array of bytes arguments, represented as hex strings
     */
    function sendRequest(
        bytes[] memory _bytesArgs
    ) internal /*onlyOwner*/ returns (bytes32 requestId_) {

        FunctionsRequest.Request memory req;

        req._initializeRequestForInlineJavaScript(SOURCE_CODE);

        if (_bytesArgs.length > 0) req._setBytesArgs(_bytesArgs);

        requestId_ = _sendRequest(
            req._encodeCBOR(),
            i_subscriptionId,
            CALLBACK_GAS_LIMIT,
            i_donId
        );

        s_requestStorage[requestId_] = RequestInfo({
            token: abi.decode(bytes(_bytesArgs[0]), (address)),
            amount: abi.decode(bytes(_bytesArgs[1]), (uint256)),
            isFulfilled: false
        });

        emit IHUBFunctions_FunctionsRequestSent(requestId_);
    }

    /**
     * @notice Function to receive the callback and start the swap
     * @param _requestId The request ID, returned by sendRequest()
     * @param _response Aggregated response from the user code
     * @param _err Aggregated error from the user code or from the execution pipeline
     * Either response or error parameter will be set, but never both
     */
    function _fulfillRequest(
        bytes32 _requestId,
        bytes memory _response,
        bytes memory _err
    ) internal override {
        RequestInfo storage request = s_requestStorage[_requestId];
        if (request.isFulfilled) revert IHUBFunctions_RequestAlreadyFulfilled(_requestId);

        if(_response.length > ZERO){
            (
                address router,
                bytes memory path,
                address inputToken,
                uint256 deadline,
                uint256 amountInForToken0,
                uint256 amountOutMin
            ) = abi.decode(_response, (address, bytes, address, uint256, uint256, uint256));

            request.isFulfilled = true;

            // LibUniswapSwaps._handleSwap(
            //     router, 
            //     path, 
            //     inputToken, 
            //     deadline, 
            //     amountInForToken0, 
            //     amountOutMin
            // );

            emit IHUBFunctions_CallbackReceivedAndSwapSucceed(_requestId);
        } else {
            emit IHUBFunctions_RequestFailed(_requestId, _err);
        }
    }
}