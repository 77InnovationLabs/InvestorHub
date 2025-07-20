///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*///////////////////////////////////
            Imports
///////////////////////////////////*/
import { MockERC20 } from "test/mocks/MockERC20.sol";

/*///////////////////////////////////
            Interfaces
///////////////////////////////////*/
import {ISwapRouter} from "@uniV3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IV3SwapRouter} from "@uni-router-v3/contracts/interfaces/IV3SwapRouter.sol";

/*///////////////////////////////////
            Libraries
///////////////////////////////////*/
import {LibUniswapV3} from "src/libraries/LibUniswapV3.sol";

contract UniswapV3RouterMock {

    function exactInput(ISwapRouter.ExactInputParams memory _params) external {

        (
            ,
            address token1
        ) = LibUniswapV3._extractTokens(_params.path);

        MockERC20(token1).mint(msg.sender, _params.amountOutMinimum);
    }
}