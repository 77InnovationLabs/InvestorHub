///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*/////////////////////////////
            Interfaces
/////////////////////////////*/
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICCIPFacets } from "src/interfaces/Chainlink/ICCIPFacets.sol";
import { INonFungiblePositionManager } from "src/interfaces/UniswapV3/INonFungiblePositionManager.sol";

/*/////////////////////////////
            Libraries
/////////////////////////////*/
import { SafeERC20 }  from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { LibTransfers } from "src/libraries/LibTransfers.sol";

/**
    @title LibInvestments
    @author 77 Innovation Labs - Chromion Hackathon
    @notice Simple library to handle investment across multiple chains
    @custom:security do not use this contracts, they were built for a Hackathon and may contain vulnerabilities
*/  
library LibInvestment {

    /*/////////////////////////////////////////////
                    Type Declarations
    /////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*///////////////////////////////////
                Events
    ///////////////////////////////////*/
    ///@notice event emitted when a new position is opened.
    event LibInvestment_PositionStarted(uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    /*/////////////////////////////////////////////
                        Functions
    /////////////////////////////////////////////*/

    /**
        @notice Internal function used by CCIPReceiveFacet contract to route Cross-chain investments
        @param _investment the payload received through the cross-chain message
    */
    function _routeInvestment(ICCIPFacets.CCInvestment memory _investment, address _target) internal {

        if(_investment.investmentTarget == ICCIPFacets.SupportedTarget.UniswapV3){

            _handleUniswapCrossChainInvestment(_investment, _target);

        } else if(_investment.investmentTarget == ICCIPFacets.SupportedTarget.AaveV3){

            //Not Supported Yet

        } else if(_investment.investmentTarget == ICCIPFacets.SupportedTarget.CompoundV3){

            //Not Supported Yet

        }
    }

    /**
        @notice Private function to open UniswapV3 positions
        @param _investment the payload receive to create Uniswap payload
    */
    function _handleUniswapCrossChainInvestment(ICCIPFacets.CCInvestment memory _investment, address _target) private {

        IERC20(_investment.token0).safeIncreaseAllowance(_target, _investment.amount0Desired);

        IERC20(_investment.token1).safeIncreaseAllowance(_target, _investment.amount1Desired);

        INonFungiblePositionManager.MintParams memory payload = INonFungiblePositionManager.MintParams({
            token0: _investment.token0,
            token1: _investment.token1,
            fee: _investment.fee,
            tickLower: _investment.tickLower,
            tickUpper: _investment.tickUpper,
            amount0Desired: _investment.amount0Desired,
            amount1Desired: _investment.amount1Desired,
            amount0Min: _investment.amount0Min,
            amount1Min: _investment.amount1Min,
            recipient: _investment.recipient,
            deadline: _investment.deadline
        });

        // Mint position and return the results
        (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = INonFungiblePositionManager(_target).mint(payload);

        // Refund any dust left in the contract
        LibTransfers._handleRefunds(_investment.recipient, _investment.token0, amount0 - _investment.amount0Min);
        LibTransfers._handleRefunds(_investment.recipient, _investment.token1, amount1 - _investment.amount1Min);

        emit LibInvestment_PositionStarted(tokenId, liquidity, amount0, amount1);
    }
}