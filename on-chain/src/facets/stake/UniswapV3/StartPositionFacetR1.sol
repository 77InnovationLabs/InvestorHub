///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*///////////////////////////////////
            Imports
///////////////////////////////////*/

/*///////////////////////////////////
            Interfaces
///////////////////////////////////*/
import { INonFungiblePositionManager } from "src/interfaces/UniswapV3/INonFungiblePositionManager.sol";

/*///////////////////////////////////
            Libraries
///////////////////////////////////*/
import { LibTransfers, SafeERC20, IERC20 } from "src/libraries/LibTransfers.sol";
import { LibUniswapV3, ISwapRouter } from "src/libraries/LibUniswapV3.sol";

contract StartPositionFacetR1 {
    /*///////////////////////////////////
            Type declarations
    ///////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*///////////////////////////////////
            State variables
    ///////////////////////////////////*/
    ///@notice immutable variable to store the diamond address
    address immutable i_diamond;
    ///@notice immutable variable to store the protocol's multisig wallet address
    address immutable i_vault;

    ///@notice immutable variable to store the UniswapV3 position manager
    INonFungiblePositionManager immutable i_positionManager;
    ///@notice immutable variable to store the UniswapV3 router
    address immutable i_uniswapRouter;
    ///@notice immutable variable to store the CCIP router address
    address immutable i_ccipRouter;

    ///@notice constant variable to store MAGIC NUMBERS
    uint8 internal constant ZERO = 0;
    ///@notice constant variable to store the maximum size of the DexPayload array
    uint8 internal constant MAX_PAYLOAD_SIZE = 10;

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
                constructor
    ///////////////////////////////////*/
    constructor(
        address _diamond,
        address _positionManager,
        address _uniswapRouter,
        address _protocolVault
    ) {
        i_diamond = _diamond;
        i_positionManager = INonFungiblePositionManager(_positionManager);
        i_uniswapRouter = _uniswapRouter;
        i_vault = _protocolVault;
        ///@dev never update state variables inside
    }

                                /*////////////////////////////////////////////////////
                                                        Functions
                                ////////////////////////////////////////////////////*/

    /**
        *@notice Creates a new liquidity position
        *@param _params inherited from INonFungiblePositionManager.MintParams
        *@param _dexPayload the data to perform swaps
    */
    function startPosition(
        INonFungiblePositionManager.MintParams memory _params,
        ISwapRouter.ExactInputParams[] memory _dexPayload
    ) external {
        if(address(this) != i_diamond) revert StartUniswapV3PositionFacet_CallerIsNotDiamond(address(this), i_diamond);
        if(_params.amount0Desired == ZERO || _params.amount1Desired == ZERO) revert StartUniswapV3PositionFacet_InvalidAmountToInvest(_params.amount0Desired, _params.amount1Desired);
        //TODO: add sanity checks

        uint256 amountOfToken0ToInvest = IERC20(_params.token0).balanceOf(address(this));
        uint256 amountOfToken1ToInvest = IERC20(_params.token1).balanceOf(address(this));

        uint256 payloadLength = _dexPayload.length;
        if(payloadLength > ZERO) {
            if(payloadLength > MAX_PAYLOAD_SIZE) revert StartUniswapV3PositionFacet_InvalidPayloadSize();

            for(uint256 i; i <  payloadLength ; ++i) {
                //transfer the totalAmountIn FROM user
                LibUniswapV3._handleSwap(i_uniswapRouter, _dexPayload[i]);
            }
        } else {
            IERC20(_params.token0).safeTransferFrom(msg.sender, address(this), _params.amount0Desired);
            IERC20(_params.token1).safeTransferFrom(msg.sender, address(this), _params.amount1Desired);
        }
        amountOfToken0ToInvest = IERC20(_params.token0).balanceOf(address(this)) - amountOfToken0ToInvest;
        amountOfToken1ToInvest = IERC20(_params.token1).balanceOf(address(this)) - amountOfToken1ToInvest;

        if(amountOfToken0ToInvest < _params.amount0Desired) revert StartUniswapV3PositionFacet_InsufficientAmountToInvest(_params.amount0Desired);
        if(amountOfToken1ToInvest - amountOfToken1ToInvest < _params.amount1Desired) revert StartUniswapV3PositionFacet_InsufficientAmountToInvest(_params.amount1Desired);

        //charge protocol fee over the totalAmountIn
        if (msg.sender != i_ccipRouter){
            _params.amount0Desired = LibTransfers._handleProtocolFee(i_vault, _params.token0, amountOfToken0ToInvest);
            _params.amount1Desired = LibTransfers._handleProtocolFee(i_vault, _params.token1, amountOfToken1ToInvest);
        }

        // Approve the tokens to be spend by the position manager
        IERC20(_params.token0).safeIncreaseAllowance(address(i_positionManager), _params.amount0Desired);
        IERC20(_params.token1).safeIncreaseAllowance(address(i_positionManager), _params.amount1Desired);

        // Mint position and return the results
        (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = i_positionManager.mint(_params);

        // Refund any dust left in the contract
        LibTransfers._handleRefunds(_params.recipient, _params.token0, _params.amount0Desired - amount0);
        LibTransfers._handleRefunds(_params.recipient, _params.token1, _params.amount1Desired - amount1);

        emit StartUniswapV3PositionFacet_PositionStarted(tokenId, liquidity, amount0, amount1);
    }
}