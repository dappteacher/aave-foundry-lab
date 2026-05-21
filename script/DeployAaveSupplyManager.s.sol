// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {AaveSupplyManager} from "../src/AaveSupplyManager.sol";

contract DeployAaveSupplyManager is Script {
    function run() external returns (AaveSupplyManager manager) {
        address pool = vm.envAddress("AAVE_POOL");
        address wrappedNativeToken = vm.envAddress("WRAPPED_NATIVE_TOKEN");
        address owner = vm.envOr("OWNER", msg.sender);

        vm.startBroadcast();
        manager = new AaveSupplyManager(pool, wrappedNativeToken, owner);
        vm.stopBroadcast();
    }
}
