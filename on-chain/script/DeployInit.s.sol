// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

///Foundry
import { Script, console } from "forge-std/Script.sol";

import { HelperConfig } from "script/helpers/HelperConfig.sol";

///Protocol Scripts
import { DeployInitialStructureScript } from "script/FacetsManagement/DeployIS.s.sol";

//Protocol Base Contracts
import { Diamond } from "../src/Diamond.sol";
import { DiamondCutFacet } from "../src/diamond/DiamondCutFacet.sol";
import { DiamondLoupeFacet } from "../src/diamond/DiamondLoupeFacet.sol";
import { DiamondInitializer } from "src/upgradeInitializers/DiamondInitializer.sol";

contract DeployInit is Script, DeployInitialStructureScript {

    function run() external returns (
        HelperConfig helperConfig_,
        address diamond_
    ) {

        console.log("1. Create Environment and Prepare Deployment Variables");
        ///@notice Deploys the Helper to access configurations for each environment
        helperConfig_ = new HelperConfig();

        console.log("2. Query Deployment Variables ");
        ///@notice Gets the config related to each particular environment
        HelperConfig.NetworkConfig memory config = helperConfig_.getConfig();

        console.log("3. Set the Deployer Key");
        vm.startBroadcast(config.admin);

        ///@notice Deploys Cut
        DiamondCutFacet cut = new DiamondCutFacet();
        console.log("4. Core Faucet __Cut__ Deployed At The Following Address:", address(cut));

        ///@notice Deploys Loupe
        DiamondLoupeFacet loupe = new DiamondLoupeFacet();
        console.log("5. Core Faucet __Loupe__ Deployed At The Following Address:", address(loupe));

        ///@notice Deploys Diamond with ADMIN, CUT and LOUPE
        diamond_ = address(new Diamond(
            config.admin,
            address(cut),
            address(loupe)
        ));
        console.log("6. Proxy Contract __Diamond__ Deployed At The Following Address:", diamond_);

        /*//////////////////////////////////////////////////////////////////////////////////////////
                            Update HelperConfig's Config Information
        //////////////////////////////////////////////////////////////////////////////////////////*/

        console.log("7. Update Local Deployment Variables: Cut, Loupe and Diamond");
        config.cutFacet = address(cut);
        config.loupeFacet = address(loupe);
        config.diamond = diamond_;

        /*//////////////////////////////////////////////////////////////////////////////////////////
                            Continue to Deploy the Business Logic Facets
        //////////////////////////////////////////////////////////////////////////////////////////*/

        console.log("8. Start Business Logic Facet Deployment:");
        ///@notice Deployment of Business Logic Facets
        handlerOfFacetDeployments(config);
        
        console.log("Protocol Completely Deployed");

        /*//////////////////////////////////////////////////////////////////////////////////////////
                                        Initialize Diamond Storage
        //////////////////////////////////////////////////////////////////////////////////////////*/
        console.log("Initialize Diamond Variables");
        DiamondInitializer(diamond_).init();
        
        vm.stopBroadcast();
    }
}