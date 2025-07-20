///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { INonFungiblePositionManager } from "src/interfaces/UniswapV3/INonFungiblePositionManager.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UniswapV3PositionMock {
    function mint(INonFungiblePositionManager.MintParams memory _param) external {
        IERC20(_param.token0).transferFrom(msg.sender, address(this), _param.amount0Min);
        IERC20(_param.token1).transferFrom(msg.sender, address(this), _param.amount1Min);
    }
}