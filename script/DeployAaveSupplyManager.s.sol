// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {AaveSupplyManager} from "../src/AaveSupplyManager.sol";
import {AaveV3Addresses} from "../src/libraries/AaveV3Addresses.sol";

contract DeployAaveSupplyManager is Script {
    function run() external returns (AaveSupplyManager manager) {
        bool useAddressBook = vm.envOr("USE_ADDRESS_BOOK", true);
        address pool;
        address wrappedNativeToken;

        if (useAddressBook) {
            AaveV3Addresses.Market memory market = AaveV3Addresses.get(block.chainid);
            pool = market.pool;
            wrappedNativeToken = market.wrappedNativeToken;
        } else {
            pool = vm.envAddress("AAVE_POOL");
            wrappedNativeToken = vm.envAddress("WRAPPED_NATIVE_TOKEN");
        }

        address owner = vm.envOr("OWNER", msg.sender);

        vm.startBroadcast();
        manager = new AaveSupplyManager(pool, wrappedNativeToken, owner);
        vm.stopBroadcast();
    }
}
