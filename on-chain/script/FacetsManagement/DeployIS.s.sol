///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

//Foundry Stuff
import { console } from "forge-std/Console.sol";

//Deploy Handler
import { HelperConfig } from "script/helpers/HelperConfig.sol";

//Protocol Base Contracts
import { DiamondCutFacet } from "src/diamond/DiamondCutFacet.sol";
import { DiamondInitializer } from "src/upgradeInitializers/DiamondInitializer.sol";
import { OwnershipFacet } from "src/diamond/OwnershipFacet.sol";

//Protocol Invest Facets
import { StartPositionFacet } from "src/facets/stake/UniswapV3/StartPositionFacet.sol";
import { CollectFeesFacet } from "src/facets/stake/UniswapV3/CollectFeesFacet.sol";
import { DecreaseLiquidityFacet } from "src/facets/stake/UniswapV3/DecreaseLiquidityFacet.sol";
import { IncreaseLiquidityFacet } from "src/facets/stake/UniswapV3/IncreaseLiquidityFacet.sol";

//Protocol Chainlink Facts
import { CCIPSendFacet } from "src/facets/Chainlink/CCIPSendFacet.sol";
import { CCIPReceiveFacet, CCIPReceiver } from "src/facets/Chainlink/CCIPReceiveFacet.sol";
import { DataFeedsFacet } from "src/facets/Chainlink/DataFeedsFacet.sol";

///Diamond Interfaces
import { IDiamondCut } from "src/interfaces/IDiamondCut.sol";

contract DeployInitialStructureScript{

    function handlerOfFacetDeployments(HelperConfig.NetworkConfig memory _config) public {

        address initialize = _addInitializeFacetToDiamond(_config.diamond);
        console.log("8.1 Business Logic Faucet __Initializer__ Deployed At The Following Address:", address(initialize));

        address ownership = _addOwnershipFacetToDiamond(_config.diamond);
        console.log("8.2 Business Logic Faucet __Ownership__ Deployed At The Following Address:", address(ownership));

        address startPosition = _addStartPositionFacet(_config);
        console.log("8.5 Business Logic Faucet __StartPosition__ Deployed At The Following Address:", address(startPosition));

        address decreasePosition = _addDecreasePositionFacet(_config);
        console.log("8.6 Business Logic Faucet __DecreasePosition__ Deployed At The Following Address:", address(decreasePosition));

        address collectPosition = _addPositionCollectFacet(_config);
        console.log("8.7 Business Logic Faucet __CollectPosition__ Deployed At The Following Address:", address(collectPosition));

        address increasePosition = _addIncreasePositionFacet(_config);
        console.log("8.8 Business Logic Faucet __IncreasePosition__ Deployed At The Following Address:", address(increasePosition));

        address ccipSend = _addCCIPSendFacet(_config);
        console.log("8.9 Business Logic Faucet __CCIPSend__ Deployed At The Following Address:", address(ccipSend));

        address ccipReceive = _addCCIPReceiveFacet(_config);
        console.log("8.10 Business Logic Faucet __CCIP Receive__ Deployed At The Following Address:", address(ccipReceive));

        address dataFeeds = _addDataFeedsFacet(_config);
        console.log("8.11 Business Logic Faucet __DataFeeds__ Deployed At The Following Address:", address(dataFeeds));
    }

    /*////////////////////////////////////////////////////////////////////////
    
                                    BASE FACETS
    
    ////////////////////////////////////////////////////////////////////////*/
    /**
        @notice Function to deploy the Diamond's initialize facet
    */
    function _addInitializeFacetToDiamond(address _diamond) internal returns(address facet_){
        
        ///@notice Deploys the initializer to populate state variables
        DiamondInitializer initializer = new DiamondInitializer();
        
        ///@notice create a memory selectors Array and Populate it
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = DiamondInitializer.init.selector;
        ///@notice create a memory FacetCut array and Populate it
        IDiamondCut.FacetCut[] memory facetCuts = new IDiamondCut.FacetCut[](1);
        facetCuts[0] = IDiamondCut.FacetCut ({
                facetAddress: address(initializer),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectors
        });
        ///@notice add `initializer` to the diamond;
        DiamondCutFacet(_diamond).diamondCut(
            facetCuts,
            _diamond,
            abi.encodeWithSelector(DiamondInitializer.init.selector)
        );

        facet_ = address(initializer);
    }
    
    /**
        @notice Function to deploy the Diamond's Ownership facet
    */
    function _addOwnershipFacetToDiamond(address _diamond) internal returns(address facet_){

        ///@notice Deploys Ownership
        OwnershipFacet ownership = new OwnershipFacet();

        ///@notice create a memory selectors Array and Populate it
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = OwnershipFacet.transferOwnership.selector;
        selectors[1] = OwnershipFacet.claimOwnership.selector;
        selectors[2] = OwnershipFacet.owner.selector;
        selectors[3] = OwnershipFacet.ownerCandidate.selector;

        ///@notice create a memory FacetCut array and Populate it
        IDiamondCut.FacetCut[] memory facetCuts = new IDiamondCut.FacetCut[](1);
        facetCuts[0] = IDiamondCut.FacetCut ({
                facetAddress: address(ownership),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectors
        });

        ///@notice add `initializer` to the diamond;
        DiamondCutFacet(_diamond).diamondCut(
            facetCuts,
            _diamond,
            abi.encodeWithSelector(DiamondInitializer.init.selector)
        );

        facet_ = address(ownership);
    }

    /*////////////////////////////////////////////////////////////////////////
    
                                INVESTMENT FACETS
    
    ////////////////////////////////////////////////////////////////////////*/

    /**
        @notice Function to deploy the facet to enable users to start a position on Uniswap
    */
    function _addStartPositionFacet(HelperConfig.NetworkConfig memory config) internal returns(address facet_){
        bytes4[] memory selectors = new bytes4[](1);

        facet_ = address(new StartPositionFacet(
            config.diamond,
            config.vault,
            config.stake.uniswapV3PositionManager,
            config.dex.universalRouter,
            config.dex.permit2
        ));

        selectors[0] = StartPositionFacet.startPosition.selector;

        ///@notice update accordingly with the action to be performed
        IDiamondCut.FacetCut memory facetCut = IDiamondCut.FacetCut({
            facetAddress: facet_,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);        
        cuts[0] = facetCut;

        DiamondCutFacet(config.diamond).diamondCut(
            cuts,
            address(0), ///@notice update it if the facet needs initialization
            "" ///@notice update it if the facet needs initialization
        );
    }

    /**
        @notice Function to deploy the facet to enable users to Decrease their positions on Uniswap
    */
    function _addDecreasePositionFacet(HelperConfig.NetworkConfig memory config) internal returns(address facet_){
        DecreaseLiquidityFacet facet = new DecreaseLiquidityFacet(
            config.diamond,
            config.stake.uniswapV3PositionManager
        );
        
        bytes4[] memory selectors = new bytes4[](1);
        ///@notice update accordingly with the action being performed
        selectors[0] = DecreaseLiquidityFacet.decreaseLiquidityCurrentRange.selector;

        ///@notice update accordingly with the action to be performed
        IDiamondCut.FacetCut memory facetCut = IDiamondCut.FacetCut({
            facetAddress: address(facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);        
        cuts[0] = facetCut;

        DiamondCutFacet(config.diamond).diamondCut(
            cuts,
            address(0), ///@notice update it if the facet needs initialization
            "" ///@notice update it if the facet needs initialization
        );

        facet_ = address(facet);
    }

    /**
        @notice Function to deploy the facet that enable users to collect their stake tokens on Uniswap
    */
    function _addPositionCollectFacet(HelperConfig.NetworkConfig memory config) internal returns(address facet_){

        CollectFeesFacet facet = new CollectFeesFacet(
            config.diamond,
            config.stake.uniswapV3PositionManager
        );

        bytes4[] memory selectors = new bytes4[](1);
        ///@notice update accordingly with the action being performed
        selectors[0] = CollectFeesFacet.collectAllFees.selector;

        ///@notice update accordingly with the action to be performed
        IDiamondCut.FacetCut memory facetCut = IDiamondCut.FacetCut({
            facetAddress: address(facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);        
        cuts[0] = facetCut;

        DiamondCutFacet(config.diamond).diamondCut(
            cuts,
            address(0), ///@notice update it if the facet needs initialization
            "" ///@notice update it if the facet needs initialization
        );

        facet_ = address(facet);
    }

    /**
        @notice Function to deploy the facet to enable users to increase their positions on Uniswap
    */
    function _addIncreasePositionFacet(HelperConfig.NetworkConfig memory config) internal returns(address facet_){
        
        IncreaseLiquidityFacet facet = new IncreaseLiquidityFacet(
            config.diamond,
            config.stake.uniswapV3PositionManager,
            config.multisig
        );
        
        bytes4[] memory selectors = new bytes4[](1);
        ///@notice update accordingly with the action being performed
        selectors[0] = IncreaseLiquidityFacet.increaseLiquidityCurrentRange.selector;

        ///@notice update accordingly with the action to be performed
        IDiamondCut.FacetCut memory facetCut = IDiamondCut.FacetCut({
            facetAddress: address(facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);        
        cuts[0] = facetCut;

        DiamondCutFacet(config.diamond).diamondCut(
            cuts,
            address(0), ///@notice update it if the facet needs initialization
            "" ///@notice update it if the facet needs initialization
        );

        facet_ = address(facet);
    }

    /*////////////////////////////////////////////////////////////////////////
    
                                CHAINLINK FACETS
    
    ////////////////////////////////////////////////////////////////////////*/

    /**
        @notice Function to deploy the facet to enable users to start cross-chain investments
    */
    function _addCCIPSendFacet(HelperConfig.NetworkConfig memory config) internal returns(address facet_){
        
        CCIPSendFacet facet = new CCIPSendFacet(
            config.diamond,
            config.vault,
            config.usdc,
            config.cl.ccipRouter,
            config.cl.linkToken,
            config.dex.universalRouter
        );
        
        bytes4[] memory selectors = new bytes4[](1);
        ///@notice update accordingly with the action being performed
        selectors[0] = CCIPSendFacet.startCrossChainInvestment.selector;

        ///@notice update accordingly with the action to be performed
        IDiamondCut.FacetCut memory facetCut = IDiamondCut.FacetCut({
            facetAddress: address(facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);        
        cuts[0] = facetCut;

        DiamondCutFacet(config.diamond).diamondCut(
            cuts,
            address(0), ///@notice update it if the facet needs initialization
            "" ///@notice update it if the facet needs initialization
        );

        facet_ = address(facet);
    }

    /**
        @notice Function to deploy the facet that allows receiving cross-chain investments
    */
    function _addCCIPReceiveFacet(HelperConfig.NetworkConfig memory config) internal returns(address facet_){
        
        CCIPReceiveFacet facet = new CCIPReceiveFacet(
            config.diamond,
            config.usdc,
            config.dex.universalRouter,
            config.stake.uniswapV3PositionManager,
            config.cl.ccipRouter
        );
        
        bytes4[] memory selectors = new bytes4[](1);
        ///@notice update accordingly with the action being performed
        selectors[0] = CCIPReceiver.ccipReceive.selector;

        ///@notice update accordingly with the action to be performed
        IDiamondCut.FacetCut memory facetCut = IDiamondCut.FacetCut({
            facetAddress: address(facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);        
        cuts[0] = facetCut;

        DiamondCutFacet(config.diamond).diamondCut(
            cuts,
            address(0), ///@notice update it if the facet needs initialization
            "" ///@notice update it if the facet needs initialization
        );

        facet_ = address(facet);
    }

    /**
        @notice Function to deploy the facet to enable link to usdc conversions
    */
    function _addDataFeedsFacet(HelperConfig.NetworkConfig memory config) internal returns(address facet_){
        
        DataFeedsFacet facet = new DataFeedsFacet(
            config.diamond,
            config.cl.feedsAggregator,
            config.cl.heartbeat
        );
        
        bytes4[] memory selectors = new bytes4[](1);
        ///@notice update accordingly with the action being performed
        selectors[0] = DataFeedsFacet.getUSDValueOfLink.selector;

        ///@notice update accordingly with the action to be performed
        IDiamondCut.FacetCut memory facetCut = IDiamondCut.FacetCut({
            facetAddress: address(facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);        
        cuts[0] = facetCut;

        DiamondCutFacet(config.diamond).diamondCut(
            cuts,
            address(0), ///@notice update it if the facet needs initialization
            "" ///@notice update it if the facet needs initialization
        );

        facet_ = address(facet);
    }
}