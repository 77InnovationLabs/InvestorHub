///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*///////////////////////////////////
            Interfaces
///////////////////////////////////*/
import { IStartPositionFacet, INonFungiblePositionManager, IUniversalRouter, IAllowanceTransfer, PoolKey } from "src/interfaces/UniswapV3/IStartPositionFacet.sol";

/*///////////////////////////////////
            Libraries
///////////////////////////////////*/
import { LibTransfers, SafeERC20, IERC20 } from "src/libraries/LibTransfers.sol";
import { LibUniswapSwaps } from "src/libraries/LibUniswapSwaps.sol";

contract StartPositionFacet is IStartPositionFacet {
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

    ///@notice immutable variable to store the Uniswap UniversalRouter address
    address immutable i_universalRouter;
    ///@notice immutable variable to store the Permit2 contract address
    address immutable i_permit2;
    ///@notice immutable variable to store the UniswapV3 position manager
    INonFungiblePositionManager immutable i_positionManager;

    ///@notice constant variable to store MAGIC NUMBERS
    uint8 internal constant ZERO = 0;
    ///@notice constant variable to store the maximum size of the DexPayload array
    uint8 internal constant MAX_PAYLOAD_SIZE = 10;

    /*///////////////////////////////////
                constructor
    ///////////////////////////////////*/
    constructor(
        address _diamond,
        address _protocolVault,
        address _positionManager,
        address _router,
        address _permit2
    ) {
        i_diamond = _diamond;
        i_vault = _protocolVault;
        i_positionManager = INonFungiblePositionManager(_positionManager);
        i_universalRouter = _router;
        i_permit2 = _permit2;

        ///@dev ⚠️ never update state variables inside ⚠️
    }

    /*////////////////////////////////////////////////////
                        External Functions
    ////////////////////////////////////////////////////*/

    /**
        *@notice Creates a new liquidity position
        *@param _params inherited from INonFungiblePositionManager.MintParams
        *@param _permitSingle the permit to transfer tokens on behalf of the user
        *@param _signature the signature to verify the permit
        *@param _key the pool keys to be used for the swap
        *@param _swapPayload the payload to perform swaps
        *@param _deadline the deadline for the swap
        *@dev this function can be called by anyone, but the caller must have enough balance to
        * cover the amounts to invest in the position.
    */
    function startPosition(
        INonFungiblePositionManager.MintParams memory _params,
        IAllowanceTransfer.PermitBatch calldata _permitSingle,
        bytes calldata _signature,
        PoolKey[] calldata _key,
        SwapPayload[] memory _swapPayload,
        uint48 _deadline
    ) external {
        if(address(this) != i_diamond) revert StartUniswapV3PositionFacet_CallerIsNotDiamond(address(this), i_diamond);
        if(_params.amount0Desired == ZERO || _params.amount1Desired == ZERO) revert StartUniswapV3PositionFacet_InvalidAmountToInvest(_params.amount0Desired, _params.amount1Desired);
        //TODO: add sanity checks

        uint256 amountOfToken0ToInvest = IERC20(_params.token0).balanceOf(address(this));
        uint256 amountOfToken1ToInvest = IERC20(_params.token1).balanceOf(address(this));

        uint256 payloadLength = _swapPayload.length;
        if(payloadLength > ZERO) {
            if(payloadLength > MAX_PAYLOAD_SIZE) revert StartUniswapV3PositionFacet_InvalidPayloadSize();

            for(uint256 i; i <  payloadLength ; ++i) {
                //transfer the totalAmountIn FROM user
                LibUniswapSwaps._handleSwap(
                    i_universalRouter, 
                    _permitSingle,
                    _signature,
                    _key,
                    _swapPayload,
                    _deadline
                );
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
        _params.amount0Desired = LibTransfers._handleProtocolFee(i_vault, _params.token0, amountOfToken0ToInvest);
        _params.amount1Desired = LibTransfers._handleProtocolFee(i_vault, _params.token1, amountOfToken1ToInvest);

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