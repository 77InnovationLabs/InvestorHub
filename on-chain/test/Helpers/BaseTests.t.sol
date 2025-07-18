// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

///Foundry 
import {Test, console} from "forge-std/Test.sol";

///Protocol Scripts
import { HelperConfig } from "script/helpers/HelperConfig.sol";
import { DeployInit } from "script/DeployInit.s.sol";

contract BaseTests is Test {
    
    /*/////////////////////////////////////////////////
                    ENVIRONMENT VARIABLES
    /////////////////////////////////////////////////*/
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig c;

    /*/////////////////////////////////////////////////
                    TOKEN AMOUNTS
    /////////////////////////////////////////////////*/
    uint256 constant USDC_INITIAL_BALANCE = 10_000e6;
    uint256 constant WETH_INITIAL_BALANCE = 100e18;

    /*/////////////////////////////////////////////////
                    GLOBAL VARIABLES
    /////////////////////////////////////////////////*/
    address d;
    address multisig;
    uint16 constant DEADLINE = 600;

    /*/////////////////////////////////////////////////
                        MOCKED USERS
    /////////////////////////////////////////////////*/
    address constant ownerCandidate = address(17);
    address constant user02 = address(2);
    address constant user03 = address(3);

    /*/////////////////////////////////////////////////
                    CALCULATION VARIABLES
    /////////////////////////////////////////////////*/
    uint8 constant BPS_FEE = 50;
    uint8 constant SLIPPAGE_FACTOR = 97;
    uint8 constant HUNDRED = 100;

    function setUp() public virtual {
        //1. Deploys DeployInit script
        DeployInit deploy = new DeployInit();

        //2. Deploy Contracts and Initiate Facets
        (
            helperConfig,
            d
        ) = deploy.run();
        //Set the configs to a global variable
        c = helperConfig.getConfig();

        //Setup
        vm.label(d, "Diamond");
        multisig = c.multisig;
        vm.label(multisig, "Multisig");

        vm.label(ownerCandidate, "OWNER_CANDIDATE");
        vm.label(user02, "USER02");
        vm.label(user03, "USER03");
    }
    
    function _calculateSlippage(uint256 _amount) internal pure returns(uint256 minAmountOut_){
        minAmountOut_ = (_amount * SLIPPAGE_FACTOR) / HUNDRED;
    }
}
