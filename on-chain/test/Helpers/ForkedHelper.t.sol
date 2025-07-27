//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

//Foundry
import { console } from "forge-std/Console.sol";

//Helpers
import { BaseTests } from "./BaseTests.t.sol";

///Interfaces
import { IStartPositionFacet, INonFungiblePositionManager } from "src/interfaces/UniswapV3/IStartPositionFacet.sol";
import { ICCIPFacets } from "src/interfaces/Chainlink/ICCIPFacets.sol";

///Open Zeppelin Tools
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

//Chainlink
import { CCIPLocalSimulatorFork, Register } from "cl/src/ccip/CCIPLocalSimulatorFork.sol";

//Uniswap
import { IStartPositionFacet, INonFungiblePositionManager } from "src/interfaces/UniswapV3/IStartPositionFacet.sol";
import { IAllowanceTransfer } from "@uniswap/permit2/src/interfaces/IAllowanceTransfer.sol";
import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import { IUniswapV3Factory } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import { IV3SwapRouter } from "@uniswap/routers/contracts/interfaces/IV3SwapRouter.sol";
import { Commands } from "@uniswap/universal-router/contracts/libraries/Commands.sol";
import { Actions } from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import { Currency } from "@uniswap/v4-core/src/types/Currency.sol";

contract ForkedHelper is BaseTests {

    /*/////////////////////////////////////////////////
                        FORK VARIABLES
    /////////////////////////////////////////////////*/
    string BASE_SEPOLIA_RPC_URL = vm.envString("BASE_SEPOLIA_RPC");
    string BASE_MAINNET_RPC_URL = vm.envString("BASE_MAINNET_RPC");
    string ARBITRUM_SEPOLIA_RPC_URL = vm.envString("ARB_SEPOLIA_RPC");
    string ARBITRUM_MAINNET_RPC_URL = vm.envString("ARB_MAINNET_RPC");
    uint256 baseSepolia;
    uint256 baseMainnet;
    uint256 arbSepolia;
    uint256 arbMainnet;

    /*/////////////////////////////////////////////////
                    Mainnet Tokens
    /////////////////////////////////////////////////*/
    address constant BASE_USDC_ADDRESS = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant BASE_WETH_ADDRESS = 0x4200000000000000000000000000000000000006;
    address constant BASE_AERO_ADDRESS = 0x940181a94A35A4569E4529A3CDfB74e38FD98631;
    address constant BASE_LINK_ADDRESS = 0x88Fb150BDc53A65fe94Dea0c9BA0a6dAf8C6e196;
    IERC20 constant BASE_USDC_MAINNET = IERC20(BASE_USDC_ADDRESS);
    IERC20 constant BASE_WETH_MAINNET = IERC20(BASE_WETH_ADDRESS);
    IERC20 constant BASE_AERO_MAINNET = IERC20(BASE_AERO_ADDRESS);
    IERC20 constant BASE_LINK_MAINNET = IERC20(BASE_LINK_ADDRESS);

    address constant ARB_USDC_ADDRESS = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address constant ARB_WETH_ADDRESS = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant ARB_ARB_ADDRESS = 0x912CE59144191C1204E64559FE8253a0e49E6548;
    address constant ARB_LINK_ADDRESS = 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4;
    IERC20 constant ARB_USDC_MAINNET = IERC20(ARB_USDC_ADDRESS);
    IERC20 constant ARB_WETH_MAINNET = IERC20(ARB_WETH_ADDRESS);
    IERC20 constant ARB_ARB_MAINNET = IERC20(ARB_ARB_ADDRESS);

    /*/////////////////////////////////////////////////
                        FACET WRAPPERS
    /////////////////////////////////////////////////*/
    IStartPositionFacet position;

    /*/////////////////////////////////////////////////
                    Uniswap Variables
    /////////////////////////////////////////////////*/
    IUniswapV3Factory factory;
    IERC721 nft;
    ///@notice Uniswap pool fee
    uint24 constant BASE_USDC_WETH_POOL_FEE = 500; //0.05%
    uint24 constant BASE_USDC_AERO_POOL_FEE = 500; //0.05%
    uint24 constant BASE_WETH_AERO_POOL_FEE = 3000; //0.3%
    uint24 constant ARB_USDC_ARB_POOL_FEE = 500; //0.05% 
    uint24 constant ARB_USDC_WETH_POOL_FEE = 500; //0.05% 
    uint24 constant ARB_WETH_ARB_POOL_FEE = 500; //0.05% 

    ///@notice Pool Range
    int24 constant MIN_TICK = -887272; // Minimum price range
    int24 constant MAX_TICK = 887272;  // Maximum price range

    /*/////////////////////////////////////////////////
                    Chainlink Variables
    /////////////////////////////////////////////////*/
    CCIPLocalSimulatorFork ccipLocal;
    uint64 constant ARB_CHAIN_SELECTOR = 4949039107694359620;
    uint256 constant CCIP_GAS_LIMIT = 1_000_000;
    address dArb;

    function setUp() public override {

        /*/////////////////////////////////////////////////
                CREATE BASE FORK E DEPLOY CONTRACTS V2
        //////////////////////////////////////////////////*/
        baseMainnet = vm.createSelectFork(BASE_MAINNET_RPC_URL);
        vm.rollFork(33_042_825);

        super.setUp();
        ccipLocal = new CCIPLocalSimulatorFork();
        _setArbitrumDetails();
        position = IStartPositionFacet(d);

        //Distribute eth balance
        deal(BASE_USDC_ADDRESS, user02, USDC_INITIAL_BALANCE);
        deal(BASE_USDC_ADDRESS, user03, USDC_INITIAL_BALANCE);
        deal(BASE_WETH_ADDRESS, user02, WETH_INITIAL_BALANCE);
        deal(BASE_WETH_ADDRESS, user03, WETH_INITIAL_BALANCE);
        deal(BASE_LINK_ADDRESS, address(d), WETH_INITIAL_BALANCE);

        //Ensure balance
        assertEq(BASE_USDC_MAINNET.balanceOf(user02), USDC_INITIAL_BALANCE);
        assertEq(BASE_USDC_MAINNET.balanceOf(user03), USDC_INITIAL_BALANCE);
        assertEq(BASE_WETH_MAINNET.balanceOf(user02), WETH_INITIAL_BALANCE);
        assertEq(BASE_WETH_MAINNET.balanceOf(user03), WETH_INITIAL_BALANCE);

        // Labeling
        vm.label(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913, "USDC");
        vm.label(0x4200000000000000000000000000000000000006, "wETH");
        vm.label(0x514910771AF9Ca656af840dff83E8264EcF986CA, "wETH");
        vm.label(c.dex.universalRouter, "UniRouterV3");

        //Uniswap Handlers
        factory = IUniswapV3Factory(c.stake.uniswapFactory);
        nft = IERC721(c.stake.uniswapV3PositionManager);

        /*/////////////////////////////////////////////////
                CREATE ARB FORK E DEPLOY CONTRACTS V1
        //////////////////////////////////////////////////*/

        arbMainnet = vm.createSelectFork(ARBITRUM_MAINNET_RPC_URL);
        vm.rollFork(359_126_776);

        super.setUp();

        //Distribute eth balance
        deal(ARB_USDC_ADDRESS, user02, USDC_INITIAL_BALANCE);
        deal(ARB_USDC_ADDRESS, user03, USDC_INITIAL_BALANCE);
        deal(ARB_WETH_ADDRESS, user02, WETH_INITIAL_BALANCE);
        deal(ARB_WETH_ADDRESS, user03, WETH_INITIAL_BALANCE);

        dArb = d;

        // Labeling
        vm.label(0xaf88d065e77c8cC2239327C5EDb3A432268e5831, "USDC");
        vm.label(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1, "wETH");
        vm.label(dArb, "Diamond Arb");

    }

    /*//////////////////////////////////////////////////////
                    Chain Switchers Modifiers
    //////////////////////////////////////////////////////*/
    modifier baseMainnetMod(){
        vm.selectFork(baseMainnet);
        _;
    }

    modifier arbMainnetMod(){
        vm.selectFork(arbMainnet);
        _;
    }

    /*//////////////////////////////////////////////////////
                        Forked Helpers
    //////////////////////////////////////////////////////*/
    /**
        * @dev Finds the nearest valid tick to either MIN_TICK or MAX_TICK based on the tickSpacing.
        * This function accounts for edge cases to ensure the returned tick is within valid range.
        * @param _nearestToMin If true, finds the nearest valid tick greater than or equal to MIN_TICK.
        *                     If false, finds the nearest valid tick less than or equal to MAX_TICK.
        * @return The nearest valid tick as an integer, ensuring it falls
        within the valid tick range.
    */
    function _findNearestValidTick(
        bool _nearestToMin,
        address _token0,
        address _token1,
        uint24 _poolFee
    ) internal view returns (int24) {
        IUniswapV3Pool pool = IUniswapV3Pool(
            factory.getPool(
                _token0 > _token1 ? _token0 : _token1,
                _token0 < _token1 ? _token0 : _token1,
                _poolFee
            )
        );

        int24 tickSpacing = pool.tickSpacing();

        if (_nearestToMin) {
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

    /*//////////////////////////////////////////////////////
                        CCIP Helpers
    //////////////////////////////////////////////////////*/
    function _setArbitrumDetails() internal {
        ccipLocal.setNetworkDetails(
            helperConfig.ARBITRUM_MAINNET_CHAIN_ID(), 
            Register.NetworkDetails({
                chainSelector: 4949039107694359620,
                routerAddress: 0x141fa059441E0ca23ce184B6A78bafD2A517DdE8,
                linkAddress: ARB_LINK_ADDRESS,
                wrappedNativeAddress: ARB_WETH_ADDRESS,
                ccipBnMAddress: address(0),
                ccipLnMAddress: address(0),
                rmnProxyAddress: 0xC311a21e6fEf769344EB1515588B9d535662a145,
                registryModuleOwnerCustomAddress: 0x1f1df9f7fc939E71819F766978d8F900B816761b,
                tokenAdminRegistryAddress: 0x39AE1032cF4B334a1Ed41cdD0833bdD7c7E7751E
            })
        );
    }

    /*//////////////////////////////////////////////////////
                        UniversalRouter Helpers
    //////////////////////////////////////////////////////*/
    function _generatePermit2Payload(address _token, uint160 _amount, uint48 _nonce) internal view returns(IAllowanceTransfer.PermitDetails memory details_){
        // Create the `PermitDetails` array
        details_ = IAllowanceTransfer.PermitDetails({
            token: _token,
            amount: _amount,
            expiration: DEADLINE,
            nonce: _nonce
        });
    }

    function _generateSwapPayload(
        bytes memory _tokenIn,
        bytes memory _tokenOut,
        bytes memory _path,
        address _recipient,
        uint256 _amountIn,
        uint256 _amountOutMinimum
    ) internal returns(IStartPositionFacet.SwapPayload memory swapPayload_){
        swapPayload_ = IStartPositionFacet.SwapPayload({
            commands: abi.encodePacked(uint8(Commands.V3_SWAP_EXACT_IN)),
            actions: abi.encodePacked(
                uint8(Actions.SWAP_EXACT_IN_SINGLE),
                uint8(Actions.SETTLE_ALL),
                uint8(Actions.TAKE_ALL)
            ),
            functionData: abi.encode(
                IV3SwapRouter.ExactInputParams({
                path: _path,
                recipient: _recipient,
                amountIn: _amountIn,
                amountOutMinimum: _amountOutMinimum
            })),
            tokenIn: _tokenIn,
            tokenOut: _tokenOut
        });
    }

    function _generateAllowanceTransferDetails(address _user, address _to, uint160 _amount, address _token) internal view returns(IAllowanceTransfer.AllowanceTransferDetails memory transfer_){
        transfer_ = IAllowanceTransfer.AllowanceTransferDetails({
            from: _user,
            to: _to,
            amount: _amount,
            token: _token
        });
    }
}