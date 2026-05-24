// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {AaveSupplyManager} from "../src/AaveSupplyManager.sol";
import {AaveV3Addresses} from "../src/libraries/AaveV3Addresses.sol";

contract DeployAaveSupplyManager is Script {
    using stdJson for string;

    function run() external returns (AaveSupplyManager manager) {
        string memory deploymentConfig = vm.envOr("DEPLOYMENT_CONFIG", string(""));
        bool useAddressBook = vm.envOr("USE_ADDRESS_BOOK", true);
        address pool;
        address wrappedNativeToken;

        if (bytes(deploymentConfig).length != 0) {
            string memory json = vm.readFile(deploymentConfig);
            pool = json.readAddress(".aave.pool");
            wrappedNativeToken = json.readAddress(".assets.wrappedNativeToken");
        } else if (useAddressBook) {
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
