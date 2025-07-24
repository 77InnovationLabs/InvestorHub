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

    ////////////////////////////////////////////////////////////////////////////////
                                /// Functions ///
    ////////////////////////////////////////////////////////////////////////////////

    /**
        *@notice Private function to handle swaps. It allows to simplify `startPosition` logic and avoid duplicated code
        *@param _router the Uniswap V3 router address
        *@param _dexPayload the data to perform swaps
    */
    function _handleSwap(
        address _router,
        ISwapRouter.ExactInputParams memory _dexPayload
    ) internal {
        // retrieve tokens from UniV3 path input
        (
            address token0,
            address token1
        ) = LibUniswapV3._extractTokens(_dexPayload.path);

        uint256 amountReceived = LibTransfers._handleTokenTransfers(token0, _dexPayload.amountIn);
        _dexPayload.amountIn = amountReceived;

        IERC20(token0).forceApprove(_router, amountReceived);

        uint256 amountOut = ISwapRouter(_router).exactInput(_dexPayload);

        if(amountOut > ZERO) LibTransfers._handleTokenTransfers(token1, amountOut);
    }

    /**
        *@notice Private function to handle swaps. It allows to simplify `startPosition` logic and avoid duplicated code
        *@param _router the Uniswap V3 router address
        *@param _dexPayload the data to perform swaps
    */
    function _handleSwap(
        address _router,
        IV3SwapRouter.ExactInputParams memory _dexPayload
    ) private {
        // retrieve tokens from UniV3 path input
        (
            address token0,
            address token1
        ) = LibUniswapV3._extractTokens(_dexPayload.path);

        uint256 amountReceived = LibTransfers._handleTokenTransfers(token0, _dexPayload.amountIn);
        _dexPayload.amountIn = amountReceived;

        IERC20(token0).safeIncreaseAllowance(_router, amountReceived);

        uint256 amountOut = IV3SwapRouter(_router).exactInput(_dexPayload);

        if(amountOut > ZERO) LibTransfers._handleTokenTransfers(token1, amountOut);
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