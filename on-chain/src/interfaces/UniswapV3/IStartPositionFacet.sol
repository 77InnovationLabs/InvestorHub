///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*/////////////////////////////
            Interfaces
/////////////////////////////*/
import { ISwapRouter } from "@uniV3-periphery/contracts/interfaces/ISwapRouter.sol";
import { IV3SwapRouter } from "@uni-router-v3/contracts/interfaces/IV3SwapRouter.sol";
import { INonFungiblePositionManager } from "src/interfaces/UniswapV3/INonFungiblePositionManager.sol";
interface IStartPositionFacet {
    function startPosition(INonFungiblePositionManager.MintParams memory _params, ISwapRouter.ExactInputParams[] memory _dexPayload) external;
    function startPosition(INonFungiblePositionManager.MintParams memory _params, IV3SwapRouter.ExactInputParams[] memory _dexPayload) external;
}