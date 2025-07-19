///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*/////////////////////////////
            Imports
/////////////////////////////*/

/*/////////////////////////////
            Interfaces
/////////////////////////////*/
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IRouterClient } from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import { IDataFeedsFacet } from "src/interfaces/Chainlink/IDataFeedsFacet.sol";
import { ICCIPFacets } from "src/interfaces/Chainlink/ICCIPFacets.sol";

/*/////////////////////////////
            Libraries
/////////////////////////////*/
import { SafeERC20 }  from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Client } from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import { LibTransfers } from "src/libraries/LibTransfers.sol";
import { LibUniswapV3 } from "src/libraries/LibUniswapV3.sol";

contract CCIPSendFacet is ICCIPFacets {

    /*/////////////////////////////////////////////
                    Type Declarations
    /////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*/////////////////////////////////////////////
                    State Variables
    /////////////////////////////////////////////*/
    ///@notice immutable variable to store the protocol multisig
    address immutable i_vault;
    ///@notice immutable variable to store the diamond address
    address immutable i_diamond;
    ///@notice immutable variable to store the USDC address
    address immutable i_usdc;
    ///@notice immutable variable to store the CCIP router address
    IRouterClient immutable i_ccipRouter;
    ///@notice immutable variable to store the LINK token address
    IERC20 immutable i_link;
    ///@notice immutable variable to store the uniswap router address
    address immutable i_uniRouter;

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

    /*//////////////////////////////
                Constructor
    //////////////////////////////*/
    constructor(
        address _diamond,
        address _vault,
        address _usdc, 
        address _ccpRouter,
        address _link,
        address _uniRouter
    ){
        i_diamond = _diamond;
        i_vault = _vault;
        i_usdc = _usdc;
        i_ccipRouter = IRouterClient(_ccpRouter);
        i_link = IERC20(_link);
        i_uniRouter = _uniRouter;
    }

    /*//////////////////////////////
                External
    //////////////////////////////*/
    /**
        @notice Entry point function for cross-chain investments
        @param _uniswapV3Payload the payload to swap ANY ERC20 token into USDC
        @param _payload the cross-chain payload populated with multiple structs
                        that represent multiple steps of a cross-chain investment
    */
    function startCrossChainInvestment(
        SwapPayload memory _uniswapV3Payload,
        CCPayload memory _payload
    ) external {
        if(address(this) != i_diamond) revert CCIPSendFacet_CallerIsNotDiamond(address(this), i_diamond);
        
        _uniswapV3Payload.totalAmountIn = LibTransfers._handleTokenTransfers(_uniswapV3Payload.inputToken, _uniswapV3Payload.totalAmountIn);

        uint256 inputTokenDust;
        uint256 swapResult;

        if(_uniswapV3Payload.inputToken != i_usdc) {
            (inputTokenDust, swapResult) = _verifySwapPayloadAndExecuteSwap(_uniswapV3Payload);
        }
        
        LibTransfers._handleRefunds(msg.sender, _uniswapV3Payload.inputToken, inputTokenDust);

        _payload.transaction.amountToSend = LibTransfers._handleProtocolFee(i_vault, i_usdc, swapResult);
        
        IERC20(i_usdc).forceApprove(address(i_ccipRouter), _payload.transaction.amountToSend);
        _ccipSend(_payload);
    }

    /*//////////////////////////////
                Private
    //////////////////////////////*/
    /**
        @notice internal function to handle the CCIP environment
        @param _payload the cross-chain payload to be sent
    */
    function _ccipSend(CCPayload memory _payload) private {

        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            _payload.transaction.receiverContract,
            _payload.transaction.amountToSend,
            abi.encode(
                _payload.swaps[0],
                _payload.swaps[1],
                _payload.investment
            ),
            _payload.transaction.extraArgs
        );

        // Get the fee required to send the CCIP message
        uint256 fees = i_ccipRouter.getFee(_payload.transaction.chainSelector, evm2AnyMessage);

        //Convert LINK -> USDC and subtract from the total to be sent.
        evm2AnyMessage.tokenAmounts[0].amount = evm2AnyMessage.tokenAmounts[0].amount - _getLinkUSDValue(fees);
            
        uint256 linkBalance = i_link.balanceOf(address(this));
        if (fees > linkBalance) revert CCIPSendFacet_NotEnoughBalance(linkBalance, fees);
            
        // approve the i_ccipRouter to transfer LINK tokens on contract's behalf. It will spend the fees in LINK
        i_link.approve(address(i_ccipRouter), fees);
            
        // Send the message through the i_ccipRouter and store the returned message ID
        bytes32 txId = i_ccipRouter.ccipSend(_payload.transaction.chainSelector, evm2AnyMessage);
            
        // Emit an event with message details
        emit CCIPSendFacet_MessageSent(txId, _payload.transaction.chainSelector, msg.sender, fees);
    }

    /**
        @notice Function to validate swap inputs and execute the swap
        @param _uniswapV3Payload the struct that contains the info needed to perform the swap
        @return inputTokenDust_ any input token lefts to be refunded
        @return swapResult_ the tokens received from the swap
    */
    function _verifySwapPayloadAndExecuteSwap(
        SwapPayload memory _uniswapV3Payload
    ) private returns(uint256 inputTokenDust_, uint256 swapResult_){
        (address token0, address token1) = LibUniswapV3._extractTokens(_uniswapV3Payload.path);
        
        if(token0 != _uniswapV3Payload.inputToken) revert CCIPSendFacet_InvalidLocalSwapInput();
        if(token1 != i_usdc) revert CCIPSendFacet_InvalidLocalSwapInput();

        (inputTokenDust_, swapResult_) = LibUniswapV3._handleSwap(
            i_uniRouter,
            _uniswapV3Payload.path,
            _uniswapV3Payload.inputToken,
            _uniswapV3Payload.deadline,
            _uniswapV3Payload.totalAmountIn,
            _uniswapV3Payload.minAmountOut
        );
    }

    /**
        @notice function to handle LINK to USDC conversion
        @param _feeInLink the amount that will be charge by CCIP
        @return linkUSDValue_ the USDC amount after conversion
    */
    function _getLinkUSDValue(uint256 _feeInLink) private returns(uint256 linkUSDValue_){
        bytes memory data = LibTransfers._handleDelegateCalls(
            i_diamond,
            abi.encodeWithSelector(
                IDataFeedsFacet.getUSDValueOfLink.selector,
                _feeInLink
            ));

        linkUSDValue_ = abi.decode(data, (uint256));
    }

    /*//////////////////////////////
                View & Pure
    //////////////////////////////*/
    /**
        * @notice Construct a CCIP message.
        * @dev This function will create an EVM2AnyMessage struct with all the necessary information for programmable tokens transfer.
        * @param _crossChainContractReceiver The address of the receiver contract.
        * @param _tokenAmount the amount to be transferred
        * @param _payload the cross-chain payload to be used
        * @param _extraArgs CCIP's extra args to customize functionality
        * @return message_ Returns an EVM2AnyMessage struct which contains information for sending a CCIP message.
    */
    function _buildCCIPMessage(
        address _crossChainContractReceiver,
        uint256 _tokenAmount,
        bytes memory _payload,
        bytes memory _extraArgs
    ) private view returns (Client.EVM2AnyMessage memory message_) {
        // Set the token amounts
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount(address(i_usdc), _tokenAmount);

        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        message_ = Client.EVM2AnyMessage({
            receiver: abi.encode(_crossChainContractReceiver),
            data: _payload,
            tokenAmounts: tokenAmounts,
            extraArgs: _extraArgs,  /*Client._argsToBytes(EVMExtraArgsV2)*/
            feeToken: address(i_link)
        });
    }
}