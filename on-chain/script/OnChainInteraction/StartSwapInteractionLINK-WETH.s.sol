// ///SPDX-License-Identifier: MIT
// pragma solidity 0.8.26;

// import { Script, console } from "forge-std/Script.sol";

// import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
// import { IUniswapV3Factory } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

// import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import { IStartSwapFacet } from "src/interfaces/UniswapV3/IStartSwapFacet.sol";
// import { IStartPositionFacet, INonFungiblePositionManager } from "src/interfaces/UniswapV3/IStartPositionFacet.sol";

// interface IWETH is IERC20{
//     function deposit() external payable;
//     function withdraw(uint256) external;
// }

// contract StartSwapInteraction is Script {
//     IUniswapV3Factory factory = IUniswapV3Factory(0x0227628f3F023bb0B980b67D528571c95c6DaC1c);
    
//     address constant DIAMOND = 0x5D8DF8b23bD15D8c01e07dE59114E7147F8C828f;

//     // General Transaction Info
//     address constant USER = 0x5FA769922a6428758fb44453815e2c436c57C3c7;
//     uint24 constant LINK_WETH_POOL_FEE = 10000; //1%
//     // uint24 constant USDC_WETH_POOL_FEE = 500; //0.5%
//     address constant LINK_SEPOLIA = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
//     address constant WETH_SEPOLIA = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
//     // address constant USDC_SEPOLIA = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
//     uint256 constant TOTAL_AMOUNT_IN = 5e18;
//     uint256 constant AMOUNT_IN_SWAP = 25e17;
//     uint256 constant AMOUNT_OUT_SWAP = 310026799623969; //Original value 0.0003809
//     uint256 constant DEADLINE = 900;
    
//     // Pool Info
//     int24 constant MIN_TICK = -887272; // Minimum price range
//     int24 constant MAX_TICK = 887272;  // Maximum price range

//     function run() external {
//         StartSwapFacet swap = StartSwapFacet(DIAMOND);

//         vm.startBroadcast(USER);

//         console.log("Transaction Starting. The caller is: ", USER);
//         console.log("The address being called is: ", DIAMOND);

//         console.log(" ======== \\========// ========");

//         console.log(unicode"Converting ETH into WETH ⏳");
//         _prepareLink();

//         console.log("Executing the StartSwap call");
//         _executeSwap(swap);

//         console.log("Transaction Finished!");
//         vm.stopBroadcast();
//     }

//     /*//////////////////////////////////////////////////////////////////
//                         Approve LINK 
//     //////////////////////////////////////////////////////////////////*/
//     function _prepareLink() internal{
//         IERC20 link = IERC20(LINK_SEPOLIA);

//         console.log("User's LINK balance is: ", link.balanceOf(USER));

//         if(link.allowance(USER, DIAMOND) < TOTAL_AMOUNT_IN){
//             link.approve(DIAMOND, TOTAL_AMOUNT_IN);
//         }
//     }

//     /*//////////////////////////////////////////////////////////////////
//                              EXECUTE TRANSACTION
//     //////////////////////////////////////////////////////////////////*/
//     function _executeSwap(StartSwapFacet _swap) internal {
//         IStartSwapFacet.DexPayload memory dexPayload = _createDexPayload();
//         INonFungiblePositionManager.MintParams memory investPayload = _createInvestPayload();

//         _swap.startSwap(
//             TOTAL_AMOUNT_IN,
//             dexPayload,
//             investPayload
//         );

//         console.log("Transaction's TOTAL_AMOUNT_IN is: ", TOTAL_AMOUNT_IN);
//     }

//     /*//////////////////////////////////////////////////////////////////
//                              CREATE DEX PAYLOAD
//     //////////////////////////////////////////////////////////////////*/
//     function _createDexPayload() internal pure returns(IStartSwapFacet.DexPayload memory dexPayload_){
//         // Swap Variables
//         bytes memory path = abi.encodePacked(
//             LINK_SEPOLIA,
//             LINK_WETH_POOL_FEE,
//             WETH_SEPOLIA
//         );

//         dexPayload_ = IStartSwapFacet.DexPayload({
//             path: path,
//             amountInForInputToken: AMOUNT_IN_SWAP,
//             deadline: 0
//         });

//         console.log("DexPayload's path created");
//         console.log("DexPayload's amountInForInputToken is: ", AMOUNT_IN_SWAP);
//         console.log("DexPayload's AMOUNT_OUT_SWAP is: ", AMOUNT_OUT_SWAP);
//     }

//     /*//////////////////////////////////////////////////////////////////
//                             CREATE INVEST PAYLOAD
//     //////////////////////////////////////////////////////////////////*/
//     function _createInvestPayload() internal view returns(INonFungiblePositionManager.MintParams memory investPayload_){
//         int24 minTick = _findNearestValidTick(true);
//         int24 maxTick = _findNearestValidTick(false);
        
//         investPayload_ = INonFungiblePositionManager.MintParams({
//             token0: address(LINK_SEPOLIA),
//             token1: address(WETH_SEPOLIA),
//             fee: LINK_WETH_POOL_FEE,
//             tickLower: minTick,
//             tickUpper: maxTick,
//             amount0Desired: AMOUNT_IN_SWAP,
//             amount1Desired: AMOUNT_OUT_SWAP,
//             amount0Min: 0,
//             amount1Min: 0,
//             recipient: USER, //Tx Executioner
//             deadline: block.timestamp + DEADLINE
//         });
        
//         console.log("InvestPayload's fee is: ", LINK_WETH_POOL_FEE);

//         console.log("InvestPayload's tickLower is: ", minTick);
//         console.log("InvestPayload's tickUpper is: ", maxTick);

//         console.log("InvestPayload's amount0Desired is: ", AMOUNT_IN_SWAP);
//         console.log("InvestPayload's amount1Desired is: ", AMOUNT_OUT_SWAP);
//     }

//     /**
//         * @dev Finds the nearest valid tick to either MIN_TICK or MAX_TICK based on the tickSpacing.
//         * This function accounts for edge cases to ensure the returned tick is within valid range.
//         * @param nearestToMin If true, finds the nearest valid tick greater than or equal to MIN_TICK.
//         *                     If false, finds the nearest valid tick less than or equal to MAX_TICK.
//         * @return The nearest valid tick as an integer, ensuring it falls
//         within the valid tick range.
//     */
//     function _findNearestValidTick(bool nearestToMin) internal view returns (int24) {
//         IUniswapV3Pool pool = IUniswapV3Pool(
//             factory.getPool(
//                 LINK_SEPOLIA > WETH_SEPOLIA ? LINK_SEPOLIA : WETH_SEPOLIA,
//                 LINK_SEPOLIA < WETH_SEPOLIA ? LINK_SEPOLIA : WETH_SEPOLIA,
//                 LINK_WETH_POOL_FEE
//             )
//         );

//         int24 tickSpacing = pool.tickSpacing();

//         if (nearestToMin) {
//             // Adjust to find a tick greater than or equal to MIN_TICK.
//             int24 adjustedMinTick = MIN_TICK + (tickSpacing - 1);
//             // Prevent potential overflow.
//             if (MIN_TICK < 0 && adjustedMinTick > 0) {
//                 adjustedMinTick = MIN_TICK;
//             }
//             int24 adjustedTick = (adjustedMinTick / tickSpacing) * tickSpacing;
//             // Ensure the adjusted tick does not fall below MIN_TICK.
//             return (adjustedTick > MIN_TICK) ? adjustedTick - tickSpacing : adjustedTick;
//         } else {
//             // Find the nearest valid tick less than or equal to MAX_TICK, straightforward due to floor division.
//             return (MAX_TICK / tickSpacing) * tickSpacing;
//         }
//     }
// }