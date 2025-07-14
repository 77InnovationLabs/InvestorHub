///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script, console } from "forge-std/Script.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IUniswapV3Factory } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import { IStartSwapFacet } from "src/interfaces/UniswapV3/IStartSwapFacet.sol";
import { StartFullSwapFacet } from "src/facets/dex/UniswapV3/StartFullSwapFacet.sol";
import { IStartPositionFacet, INonFungiblePositionManager } from "src/interfaces/UniswapV3/IStartPositionFacet.sol";

interface IWETH is IERC20{
    function deposit() external payable;
    function withdraw(uint256) external;
}

contract StartFullSwapInteraction is Script {
    IUniswapV3Factory factory = IUniswapV3Factory(0x0227628f3F023bb0B980b67D528571c95c6DaC1c);
    
    address constant DIAMOND = 0x5D8DF8b23bD15D8c01e07dE59114E7147F8C828f;

    // General Transaction Info
    address constant USER = 0x5FA769922a6428758fb44453815e2c436c57C3c7;
    uint24 constant LINK_WETH_POOL_FEE = 10000; //1%
    uint24 constant WETH_USDT_POOL_FEE = 10000; //1% //USDT/ETH
    uint24 constant USDC_USDT_POOL_FEE = 500; //0.05% //USDC/USDT
    uint24 constant USDC_WETH_POOL_FEE = 500; //0.05% //USDC/WETH
    address constant INPUT_TOKEN_WETH = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    address constant LINK_SEPOLIA = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address constant USDC_SEPOLIA = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address constant USDT_SEPOLIA = 0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0;
    uint256 constant TOTAL_AMOUNT_IN = 0.002 ether;
    uint256 constant AMOUNT_IN_SWAP = 0.001 ether;
    uint256 constant AMOUNT_DESIRED_USDT = 5_599_970_000;
    uint256 constant AMOUNT_DESIRED_USDC = 54_552_400;
    uint256 constant DEADLINE = 60;
    
    // Pool Info
    int24 constant MIN_TICK = -887272; // Minimum price range
    int24 constant MAX_TICK = 887272;  // Maximum price range

    /*
        USDC - USDT: https://www.geckoterminal.com/sepolia-testnet/pools/0xfef3ae91e2050accb4da6033c6eb3b1bc4e3a1a5
        USDC - wETH: https://www.geckoterminal.com/sepolia-testnet/pools/0x3289680dd4d6c10bb19b899729cda5eef58aeff1
        USDT - wETH: https://www.geckoterminal.com/sepolia-testnet/pools/0x46bb6bb1b27069c652aa40ddbf47854b1c426428
    */

    function run() external {
        StartFullSwapFacet swap = StartFullSwapFacet(DIAMOND);

        vm.startBroadcast(USER);

        console.log("Transaction Starting. The caller is: ", USER);
        console.log("The address being called is: ", DIAMOND);

        console.log(" ======== \\========// ========");

        console.log(unicode"Converting ETH into WETH ⏳");
        _prepareWETH();

        console.log("Executing the StartSwap call");
        _executeSwap(swap);

        console.log("Transaction Finished!");
        vm.stopBroadcast();
    }

    /*//////////////////////////////////////////////////////////////////
                        CONVERT ETH -> WETH & APPROVALS
    //////////////////////////////////////////////////////////////////*/
    function _prepareWETH() internal{
        IWETH wETH = IWETH(INPUT_TOKEN_WETH);

        if(wETH.balanceOf(USER) < TOTAL_AMOUNT_IN){
            console.log("Amount of ETH deposited is: ", TOTAL_AMOUNT_IN);
            wETH.deposit{value: TOTAL_AMOUNT_IN}();
        }
        console.log("Amount of wETH balance is: ", wETH.balanceOf(USER));

        if(wETH.allowance(USER, DIAMOND) < TOTAL_AMOUNT_IN){
            wETH.approve(DIAMOND, TOTAL_AMOUNT_IN);
        }
    }

    /*//////////////////////////////////////////////////////////////////
                             EXECUTE TRANSACTION
    //////////////////////////////////////////////////////////////////*/
    function _executeSwap(StartFullSwapFacet _swap) internal {
        IStartSwapFacet.DexPayload[] memory dexPayload = new IStartSwapFacet.DexPayload[](2);
        dexPayload = _createDexPayload();
        INonFungiblePositionManager.MintParams memory investPayload = _createInvestPayload();

        _swap.startSwap(
            INPUT_TOKEN_WETH,
            TOTAL_AMOUNT_IN,
            dexPayload,
            investPayload
        );
    }

    /*//////////////////////////////////////////////////////////////////
                             CREATE DEX PAYLOAD
    //////////////////////////////////////////////////////////////////*/
    function _createDexPayload() internal pure returns(IStartSwapFacet.DexPayload[] memory dexPayload_){
        IStartSwapFacet.DexPayload[] memory dexPayload = new IStartSwapFacet.DexPayload[](2);

        // Swap Variables
        bytes memory path0 = abi.encodePacked(
            INPUT_TOKEN_WETH,
            WETH_USDT_POOL_FEE,
            USDT_SEPOLIA
        );

        dexPayload[0] = IStartSwapFacet.DexPayload({
            path: path0,
            amountInForInputToken: AMOUNT_IN_SWAP,
            deadline: 0
        });

        bytes memory path1 = abi.encodePacked(
            INPUT_TOKEN_WETH,
            USDC_WETH_POOL_FEE,
            USDC_SEPOLIA
        );

        dexPayload[1] = IStartSwapFacet.DexPayload({
            path: path1,
            amountInForInputToken: AMOUNT_IN_SWAP,
            deadline: 0
        });

        dexPayload_ = dexPayload;

        console.log("DexPayload's path created");
    }

    /*//////////////////////////////////////////////////////////////////
                            CREATE INVEST PAYLOAD
    //////////////////////////////////////////////////////////////////*/
    function _createInvestPayload() internal view returns(INonFungiblePositionManager.MintParams memory investPayload_){
        int24 minTick = _findNearestValidTick(true);
        int24 maxTick = _findNearestValidTick(false);

        investPayload_ = INonFungiblePositionManager.MintParams({
            token0: address(USDT_SEPOLIA),
            token1: address(USDC_SEPOLIA),
            fee: USDC_USDT_POOL_FEE,
            tickLower: minTick,
            tickUpper: maxTick,
            amount0Desired: AMOUNT_DESIRED_USDT,
            amount1Desired: AMOUNT_DESIRED_USDC,
            amount0Min: (AMOUNT_DESIRED_USDT * 95) / 100,
            amount1Min: (AMOUNT_DESIRED_USDC * 95) / 100,
            recipient: USER, //Tx Executioner
            deadline: block.timestamp
        });
        
        console.log("InvestPayload's fee is: ", USDC_USDT_POOL_FEE);

        console.log("InvestPayload's tickLower is: ", minTick);
        console.log("InvestPayload's tickUpper is: ", maxTick);

        console.log("InvestPayload's Amount Desired USDT is: ", AMOUNT_DESIRED_USDT);
        console.log("InvestPayload's Amount Desired USDC is: ", AMOUNT_DESIRED_USDC);
    }

    /**
        * @dev Finds the nearest valid tick to either MIN_TICK or MAX_TICK based on the tickSpacing.
        * This function accounts for edge cases to ensure the returned tick is within valid range.
        * @param nearestToMin If true, finds the nearest valid tick greater than or equal to MIN_TICK.
        *                     If false, finds the nearest valid tick less than or equal to MAX_TICK.
        * @return The nearest valid tick as an integer, ensuring it falls
        within the valid tick range.
    */
    function _findNearestValidTick(bool nearestToMin) internal view returns (int24) {
        IUniswapV3Pool pool = IUniswapV3Pool(
            factory.getPool(
                USDT_SEPOLIA > USDC_SEPOLIA ? USDT_SEPOLIA : USDC_SEPOLIA,
                USDT_SEPOLIA < USDC_SEPOLIA ? USDT_SEPOLIA : USDC_SEPOLIA,
                USDC_USDT_POOL_FEE
            )
        );

        int24 tickSpacing = pool.tickSpacing();

        if (nearestToMin) {
            // Adjust to find a tick greater than or equal to MIN_TICK.
            int24 adjustedMinTick = MIN_TICK + (tickSpacing - 1);
            // Prevent potential overflow.
            if (MIN_TICK < 0 && adjustedMinTick > 0) {
                adjustedMinTick = MIN_TICK;
            }
            int24 adjustedTick = (adjustedMinTick / tickSpacing) * tickSpacing;
            // Ensure the adjusted tick does not fall below MIN_TICK.
            return (adjustedTick > MIN_TICK) ? adjustedTick - tickSpacing : adjustedTick;
        } else {
            // Find the nearest valid tick less than or equal to MAX_TICK, straightforward due to floor division.
            return (MAX_TICK / tickSpacing) * tickSpacing;
        }
    }
}

// MintParams({ 
//     token0: 0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0, 
//     token1: 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238, 
//     fee: 500, 
//     tickLower: -887270 [-8.872e5], 
//     tickUpper: 887270 [8.872e5], 
//     amount0Desired: 9_245_102_690 [9.245e9], 
//     amount1Desired: 75_451_039 [7.545e7], 
//     amount0Min: 5_319_971_500 [5.319e9], 
//     amount1Min: 51_824_780 [5.182e7], 
//     recipient: 0x5FA769922a6428758fb44453815e2c436c57C3c7,
//     deadline: 1752284964 [1.752e9]
// })

// -9433778255 [-9.433e9], amount1: 1000000000000000
// -76990856 [-7.699e7], amount1: 1000000000000000