// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script,console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscription is Script {

    function createSubscriptionUsingConfig() public returns(uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256 subId, ) = createSubscription(vrfCoordinator);
        return (subId,vrfCoordinator);
    }


    function createSubscription(address vrfCoordinator) public returns(uint256, address) {
        console.log("creating subscriptionid on chainid:", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Your Subscription Id is:", subId);
        console.log("Update subscriptionId in you HelperConfig file");

        return (subId,vrfCoordinator);
    }


    function run() public {
        createSubscriptionUsingConfig();
    }

}


contract FundSubscription is Script {
    uint256 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        fundSubscription(vrfCoordinator, subscriptionId, linkToken);
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address link) public {
        console.log("Funding subscription:",subscriptionId);
        console.log("Using vrfCoordinator:", vrfCoordinator);
        console.log("on ChainId:", block.chainid);

        // if (block.chainid == LOCAL_CHAIN_ID) {
        //     vm.startBroadcast();
        //     VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
        //     vm.stopBroadcast();
        // }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }

}