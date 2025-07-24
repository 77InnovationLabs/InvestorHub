///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*/////////////////////////////
            Imports
/////////////////////////////*/
import { CCIPReceiver } from "@chainlink/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";

/*/////////////////////////////
            Interfaces
/////////////////////////////*/
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICCIPFacets } from "src/interfaces/Chainlink/ICCIPFacets.sol";

/*/////////////////////////////
            Libraries
/////////////////////////////*/
import { SafeERC20 }  from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Client } from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import { LibTransfers } from "src/libraries/LibTransfers.sol";
import { LibUniswapV3 } from "src/libraries/LibUniswapV3.sol";
import { LibInvestment } from "src/libraries/LibInvestment.sol";

contract CCIPReceiveFacet is CCIPReceiver {

    /*/////////////////////////////////////////////
                    Type Declarations
    /////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*/////////////////////////////////////////////
                    State Variables
    /////////////////////////////////////////////*/
    ///@notice immutable variable to store the diamond address
    address immutable i_diamond;
    ///@notice immutable variable to store the usdc address
    IERC20 immutable i_usdc;
    ///@notice immutable variables to store the Uniswap router and position handle
    address immutable i_uniRouter;
    address immutable i_uniPosition;

    ///@notice constant variable to store MAGIC NUMBERS
    uint8 private constant ZERO = 0;

    /*/////////////////////////////////////////////
                        Events
    /////////////////////////////////////////////*/
    ///@notice event emitted when the payload call fails
    event CCIPReceiveFacet_CallFailed(uint256 iteration, bytes data);

    /*/////////////////////////////////////////////
                        Error
    /////////////////////////////////////////////*/
    ///@notice error emitted when the function is not executed in the Diamond context
    error CCIPReceiveFacet_CallerIsNotDiamond(address actualContext, address diamondContext);
    ///@notice error emitted if one of the calls has the diamond as target
    error CCIPReceiveFacet_CannotCallTheDiamond();
    ///@notice error emitted when the amount of tokens used is bigger than the amount received
    error CCIPReceiveFacet_IncorrectAmountOfTokensSpent();

                                    /*/////////////////////////////////////////////
                                                        Functions
                                    /////////////////////////////////////////////*/
    

    /*//////////////////////////////
                Modifiers
    //////////////////////////////*/

    /*//////////////////////////////
                Constructor
    //////////////////////////////*/
    constructor(
        address _diamond, 
        address _usdc, 
        address _uniRouter,
        address _uniPositionManager,
        address _router
    ) CCIPReceiver(_router){
        i_diamond = _diamond;
        i_usdc = IERC20(_usdc);
        i_uniRouter = _uniRouter;
        i_uniPosition = _uniPositionManager;
    }

    /*//////////////////////////////
                Private
    //////////////////////////////*/
    /**
        @notice Function to handle cross-chain operations
        @param _message the CCIP payload received
    */
    function _ccipReceive( //Add access control [using storage 🥲]
        Client.Any2EVMMessage memory _message
    ) internal override {
        if(address(this) != i_diamond) revert CCIPReceiveFacet_CallerIsNotDiamond(address(this), i_diamond);

        uint256 contractInitialBalance = i_usdc.balanceOf(address(this)) - _message.destTokenAmounts[0].amount;
        ICCIPFacets.CCPayload memory ccPayload;
        (
            ccPayload.swaps[0],
            ccPayload.swaps[1], //if needed
            ccPayload.investment
        ) = abi.decode(
            _message.data,
            (
                ICCIPFacets.SwapPayload, 
                ICCIPFacets.SwapPayload,
                ICCIPFacets.CCInvestment
            )
        );

        /**
            @question How to improve the logic below?
            **** Cross-chain transaction will always have ****
            1. USDC as input token
            2. At least one approve to invest a token
            3. One call to Invest a token

            **** Cross-chain transactions could have *****
            1. Approve of total USDC amount to swap the USDC into one or two different tokens
            2. One or two calls to Swap
        */
        i_usdc.safeIncreaseAllowance(i_uniRouter, _message.destTokenAmounts[0].amount);

        if(ccPayload.swaps[0].path.length > ZERO){
            (uint256 token0Dust, uint256 amountReceived) = LibUniswapV3._handleSwap(
                i_uniRouter, 
                ccPayload[0]
            );

            if(token0Dust > ZERO) LibTransfers._handleRefunds(ccPayload.investment.recipient, ccPayload.swaps[0].inputToken, token0Dust);
        }
        if(ccPayload.swaps[1].path.length > ZERO){
            (uint256 token0Dust, uint256 amountReceived) = LibUniswapV3._handleSwap(
                i_uniRouter, 
                ccPayload[1]
            );

            if(token0Dust > ZERO) LibTransfers._handleRefunds(ccPayload.investment.recipient, ccPayload.swaps[1].inputToken, token0Dust);
        }

        LibInvestment._routeInvestment(ccPayload.investment, i_uniPosition);

        if(i_usdc.balanceOf(address(this)) >= contractInitialBalance) revert CCIPReceiveFacet_IncorrectAmountOfTokensSpent();
    }


    /*//////////////////////////////
                View & Pure
    //////////////////////////////*/

}

/**
    User
    * Stake Link & USDC in Arbitrum's UniswapV3
    -> Start call [ETH]
        -> Convert into USDC?
        -> Calls CCIP and initiate Cross-chain transfer.
        -> Receives USDC tokenAmounts[0]
        -> Receives a Data payload
            -> encoded call to UniV3 Swap
                Must approve USDC received before
            -> encoded call to UniV3 stake function
                Must approve UniV3 for both tokens
            -> Must remove any dust from the contract, sending back to user.
*/