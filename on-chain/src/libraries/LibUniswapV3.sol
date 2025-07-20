//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*/////////////////////////////
            Interfaces
/////////////////////////////*/
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISwapRouter} from "@uniV3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IV3SwapRouter} from "@uni-router-v3/contracts/interfaces/IV3SwapRouter.sol";

/*/////////////////////////////
            Libraries
/////////////////////////////*/
import { Bytes } from "@openzeppelin/contracts/utils/Bytes.sol";

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

    /*///////////////////////////////////
                    Errors
    ///////////////////////////////////*/

    ////////////////////////////////////////////////////////////////////////////////
                                /// Functions ///
    ////////////////////////////////////////////////////////////////////////////////
    function _handleSwap(
        address _router,
        bytes memory _path,
        address _inputToken,
        uint256 _deadline,
        uint256 _amountForTokenIn,
        uint256 _amountOutMin
    ) internal returns(uint256 token0left_, uint256 swappedAmount_){
        // TODO: Comunicar o Front
        if(_deadline > ZERO){
            (token0left_, swappedAmount_) = _handleSwapV1(
                _router,
                _path,
                _inputToken,
                _deadline,
                _amountForTokenIn,
                _amountOutMin
            );
        } else {
            (token0left_, swappedAmount_) = _handleSwapsV3(
                _router,
                _path,
                _inputToken,
                _amountForTokenIn,
                _amountOutMin
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
        bytes memory _path,
        address _inputToken,
        uint256 _deadline,
        uint256 _amountForTokenIn,
        uint256 _amountOutMin
    ) private returns(uint256 token0left_, uint256 swappedAmount_){

        //handle payload - forward the liquidAmount
        ISwapRouter.ExactInputParams memory dexPayload = ISwapRouter.ExactInputParams({
            path: _path,
            recipient: address(this), ///@notice swaps must have the Diamond address as receiver
            deadline: _deadline,
            amountIn: _amountForTokenIn,
            amountOutMinimum: _amountOutMin
        });

        //Safe approve _router for the _amountForTokenIn
        IERC20(_inputToken).safeIncreaseAllowance(_router, _amountForTokenIn);

        //Swap
        swappedAmount_ = ISwapRouter(_router).exactInput(dexPayload);

        token0left_ = IERC20(_inputToken).balanceOf(address(this));
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
        bytes memory _path,
        address _inputToken,
        uint256 _amountForTokenIn,
        uint256 _amountOutMin
    ) private returns(uint256 token0left_, uint256 swappedAmount_){

        //handle payload - forward the liquidAmount
        IV3SwapRouter.ExactInputParams memory dexPayload = IV3SwapRouter.ExactInputParams({
            path: _path,
            recipient: address(this), ///@notice swaps must have the Diamond address as receiver
            amountIn: _amountForTokenIn,
            amountOutMinimum: _amountOutMin
        });

        //Safe approve _router for the _amountForTokenIn
        IERC20(_inputToken).safeIncreaseAllowance(_router, _amountForTokenIn);

        //Swap
        swappedAmount_ = IV3SwapRouter(_router).exactInput(dexPayload);

        token0left_ = IERC20(_inputToken).balanceOf(address(this));
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