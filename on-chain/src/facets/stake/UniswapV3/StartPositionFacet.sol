///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*///////////////////////////////////
            Interfaces
///////////////////////////////////*/
import { IStartPositionFacet, INonFungiblePositionManager, IPermit2 } from "src/interfaces/UniswapV3/IStartPositionFacet.sol";

/*///////////////////////////////////
            Libraries
///////////////////////////////////*/
import { LibTransfers, SafeERC20, IERC20 } from "src/libraries/LibTransfers.sol";
import { LibUniswapSwaps, IUniversalRouter } from "src/libraries/LibUniswapSwaps.sol";

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
    IPermit2 immutable i_permit2;
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
        i_permit2 = IPermit2(_permit2);

        ///@dev ⚠️ never update state variables inside ⚠️
    }

    /*////////////////////////////////////////////////////
                        External Functions
    ////////////////////////////////////////////////////*/

    /**
        *@notice Creates a new liquidity position
        *@param _params inherited from INonFungiblePositionManager.MintParams
        *@param _permitBatch the permit to transfer tokens on behalf of the user
        *@param _signature the signature to verify the permit
        *@param _transferDetails the Permit2 data to transfer the investment tokens
        *@param _swapPayload the payload to perform swaps
        *@param _deadline the deadline for the swap
        
        *@dev Things that this function must be able to do:
        1. Receive one investment token, and some arbitrary - Would require swaps to only one of the investment token
        2. Receive both token needed to create an investment.
        3. Receive none of the token to invest and still handle up to teen swaps and execute the investment.
    */
    function startPosition(
        INonFungiblePositionManager.MintParams memory _params,
        IPermit2.PermitBatch calldata _permitBatch,
        bytes calldata _signature,
        IPermit2.AllowanceTransferDetails[] memory _transferDetails,
        SwapPayload[] memory _swapPayload,
        uint48 _deadline
    ) external {
        if(address(this) != i_diamond) revert StartPositionFacet_CallerIsNotDiamond(address(this), i_diamond);
        if(_params.amount0Desired == ZERO || _params.amount1Desired == ZERO) revert StartPositionFacet_InvalidAmountToInvest(_params.amount0Desired, _params.amount1Desired);
        if(_swapPayload.length > MAX_PAYLOAD_SIZE) revert StartPositionFacet_InvalidPayloadSize();
        //TODO: add sanity checks

        uint256 contractAmountOfToken0ToInvest = IERC20(_params.token0).balanceOf(address(this));
        uint256 contractAmountOfToken1ToInvest = IERC20(_params.token1).balanceOf(address(this));

        //TODO if only one swap is performed, the contract will have only half of the money
        //We need to ensure the total amount is transferred in a scenario the user has
        //one of the tokens
        if(_swapPayload.length > ZERO)  {
            LibUniswapSwaps._handleSwap(i_universalRouter,  _permitBatch, _signature, _swapPayload, _deadline);
        } else {
            i_permit2.transferFrom(_transferDetails);
        }

        uint256 receivedAmountOfToken0ToInvest = IERC20(_params.token0).balanceOf(address(this)) - contractAmountOfToken0ToInvest;
        uint256 receivedAmountOfToken1ToInvest = IERC20(_params.token1).balanceOf(address(this)) - contractAmountOfToken1ToInvest;

        if(receivedAmountOfToken0ToInvest < _params.amount0Desired) revert StartPositionFacet_InsufficientAmountToInvest(receivedAmountOfToken0ToInvest);
        if(receivedAmountOfToken1ToInvest < _params.amount1Desired) revert StartPositionFacet_InsufficientAmountToInvest(receivedAmountOfToken1ToInvest);

        //charge protocol fee over the totalAmountIn
        _params.amount0Desired = LibTransfers._handleProtocolFee(i_vault, _params.token0, receivedAmountOfToken0ToInvest);
        _params.amount1Desired = LibTransfers._handleProtocolFee(i_vault, _params.token1, receivedAmountOfToken1ToInvest);

        // Mint position and return the results
        (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = i_positionManager.mint(_params);

        // Refund any dust left in the contract
        LibTransfers._handleRefunds(_params.recipient, _params.token0, _params.amount0Desired - amount0);
        LibTransfers._handleRefunds(_params.recipient, _params.token1, _params.amount1Desired - amount1);

        emit StartPositionFacet_PositionStarted(tokenId, liquidity, amount0, amount1);
    }
}