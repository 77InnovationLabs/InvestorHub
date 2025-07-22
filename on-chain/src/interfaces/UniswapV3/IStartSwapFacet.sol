///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { INonFungiblePositionManager } from "src/interfaces/UniswapV3/INonFungiblePositionManager.sol";

interface IStartSwapFacet {

    /*///////////////////////////////////
                    Variables
    ///////////////////////////////////*/


    function startSwap(
        uint256 _totalAmountIn,
        DexPayload memory _payload,
        INonFungiblePositionManager.MintParams memory _stakePayload
    ) external;

    function startSwap(
        address _inputToken,
        uint256 _totalAmountIn,
        IStartSwapFacet.DexPayload[] memory _payload,
        INonFungiblePositionManager.MintParams memory _stakePayload
    ) external;
}