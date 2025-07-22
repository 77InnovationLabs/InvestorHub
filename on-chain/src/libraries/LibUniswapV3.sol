//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*/////////////////////////////
            Interfaces
/////////////////////////////*/
import { IStartSwapFacet } from "src/interfaces/UniswapV3/IStartSwapFacet.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISwapRouter} from "@uniV3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IV3SwapRouter} from "@uni-router-v3/contracts/interfaces/IV3SwapRouter.sol";

/*/////////////////////////////
            Libraries
/////////////////////////////*/
import { Bytes } from "@openzeppelin/contracts/utils/Bytes.sol";
import { LibTransfers } from "src/libraries/LibTransfers.sol";

library LibUniswapV3{

    /*///////////////////////////////////
             Type declarations
    ///////////////////////////////////*/   
    using SafeERC20 for IERC20; 
    using Bytes for bytes;

    /*/////////////////////////////////////////////
                    State Variables
    /////////////////////////////////////////////*/
    ///@notice constant variable to store MAGIC NUMBERS
    uint8 private constant ZERO = 0;
    ///@notice constant variable to store the maximum size of the DexPayload array
    uint8 private constant MAX_PAYLOAD_SIZE = 10;

    /*///////////////////////////////////
                    Errors
    ///////////////////////////////////*/
    ///@notice error emitted when the function is not executed in the Diamond context
    error StartSwapFacet_CallerIsNotDiamond(address actualContext, address diamondContext);
    ///@notice error emitted when the liquidAmount is zero
    error StartSwapFacet_InvalidAmountToSwap(uint256 amountIn);
    ///@notice error emitted when the first token of a swap is the address(0)
    error StartSwapFacet_InvalidToken0(address tokenIn);
    ///@notice error emitted when the token out is != than USDC
    error StartSwapFacet_InvalidToken1(address tokenOut);
    ///@notice error emitted when the payload size is greater than the maximum allowed
    error StartSwapFacet_InvalidPayloadSize();

    ////////////////////////////////////////////////////////////////////////////////
                                /// Functions ///
    ////////////////////////////////////////////////////////////////////////////////
    /**
        *@notice external function to handle the creation of an investment position
        *@param _payload the data to perform swaps
        *@param _stakePayload the data to perform the stake operation
        *@dev this function must be able to perform swaps and stake the tokens
        *@dev the stToken must be sent directly to user.
        *@dev the _stakePayload must contain the final value to be deposited, the calculations
    */
    function startSwap(
        address _router,
        IERC20 _usdc,
        ISwapRouter.ExactInputParams[] memory _dexPayload
    ) external returns(uint256 usdcReceived_) {
        uint256 payloadLength = _dexPayload.length;
        if(payloadLength > MAX_PAYLOAD_SIZE) revert StartSwapFacet_InvalidPayloadSize();

        // Move to Investment Facet
        // if(_payload[payloadLength -2].tokenIn != address(i_usdc)) revert StartSwapFacet_InvalidToken0(_payload[payloadLength -2].tokenIn);
        // if(_payload[payloadLength -2].tokenOut != _stakePayload.token0) revert StartSwapFacet_InvalidToken1(_payload[payloadLength -2].tokenOut);
        // if(_payload[payloadLength -1].tokenIn != address(i_usdc)) revert StartSwapFacet_InvalidToken0(_payload[payloadLength -1].tokenIn);
        // if(_payload[payloadLength -1].tokenOut != _stakePayload.token1) revert StartSwapFacet_InvalidToken1(_payload[payloadLength -1].tokenOut);


        for(uint256 i; i <  payloadLength ; ++i) {
            // retrieve tokens from UniV3 path input
            (
                address token0,
                address token1
            ) = LibUniswapV3._extractTokens(_dexPayload.path);

            //TODO: Sanity checks
            if(token1 != _usdc) revert StartSwapFacet_InvalidToken1(token1);
                
            _dexPayload.amountInForInputToken = LibTransfers._handleTokenTransfers(token0, _dexPayload.amountInForInputToken);
            
            _handleSwap(_router, _dexPayload);
        }

    }
    
    function _handleSwap(
        address _router,
        ISwapRouter.ExactInputParams memory _dexPayload
    ) internal returns(uint256 token0left_, uint256 swappedAmount_){
        // TODO: Comunicar o Front
        if(_deadline > ZERO){
            (token0left_, swappedAmount_) = _handleSwapV1(
                _router,
                _dexPayload
            );
        } else {
            (token0left_, swappedAmount_) = _handleSwapsV3(
                _router,
                _dexPayload
            );
        }
    }

    /**
        *@notice Private function to handle swaps. It allows to simplify `startPosition` logic and avoid duplicated code
        *@param _path the Uniswap pattern path to swap on v3 model
        *@param _inputToken the token to be swapped
        *@param _amountForTokenIn the amount of tokens to swap
        *@param _amountOutMin the minimum accepted amount to receive from the swap
        *@return token0left_ the amount of token zero left in the contract
        *@return swappedAmount_ the result from the swap process
    */
    function _handleSwapV1(
        address _router,
        ISwapRouter.ExactInputParams memory _dexPayload
    ) private returns(uint256 swappedAmount_){

        //Safe approve _router for the _amountForTokenIn
        IERC20(_inputToken).forceApprove(_router, _amountForTokenIn);

        swappedAmount_ = ISwapRouter(_router).exactInput(_dexPayload);
    }

    /**
        *@notice Private function to handle swaps. It allows to simplify `startPosition` logic and avoid duplicated code
        *@param _path the Uniswap pattern path to swap on v3 model
        *@param _inputToken the token to be swapped
        *@param _amountForTokenIn the amount of tokens to swap
        *@param _amountOutMin the minimum accepted amount to receive from the swap
        *@return token0left_ the amount of token zero left in the contract
        *@return swappedAmount_ the result from the swap process
    */
    function _handleSwapsV3(
        address _router,
        IV3SwapRouter.ExactInputParams memory _dexPayload
    ) private returns(uint256 swappedAmount_){
        //Safe approve _router for the _amountForTokenIn
        IERC20(_inputToken).safeIncreaseAllowance(_router, _amountForTokenIn);
        //Swap
        swappedAmount_ = IV3SwapRouter(_router).exactInput(_dexPayload);
    }

    /*//////////////////////////////////
                VIEW & PURE
    //////////////////////////////////*/
    /**
        *@notice helper function to extract tokens from bytes data
        *@dev should extract the first and last tokens.
        *@return _tokenIn the token that will be the input
        *@return _tokenOut the token that will be the final output
    */
    function _extractTokens(
        bytes memory _path
    ) internal pure returns (address _tokenIn, address _tokenOut) {
        uint256 pathSize = _path.length;

        bytes memory tokenBytes = _path.slice(0, 20);

        assembly {
            _tokenIn := mload(add(tokenBytes, 20))
        }

        bytes memory secondTokenBytes = _path.slice(pathSize - 20, pathSize);

        assembly {
            _tokenOut := mload(add(secondTokenBytes, 20))
        }
    }
}