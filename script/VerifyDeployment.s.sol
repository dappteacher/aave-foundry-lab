// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {AaveSupplyManager} from "../src/AaveSupplyManager.sol";
import {AaveV3Addresses} from "../src/libraries/AaveV3Addresses.sol";

contract VerifyDeployment is Script {
    using stdJson for string;

    error DeploymentMismatch(string field, address expected, address actual);
    error DeploymentBoolMismatch(string field, bool expected, bool actual);
    error PendingOwnerSet(address pendingOwner);

    struct ExpectedDeployment {
        address manager;
        address pool;
        address wrappedNativeToken;
        address owner;
        bool paused;
    }

    function run() external view {
        ExpectedDeployment memory expected = expectedFromEnvironment();
        verify(expected);
    }

    function expectedFromEnvironment() public view returns (ExpectedDeployment memory expected) {
        expected.manager = vm.envAddress("MANAGER");
        expected.owner = vm.envAddress("OWNER");
        expected.paused = vm.envOr("EXPECTED_PAUSED", false);

        string memory deploymentConfig = vm.envOr("DEPLOYMENT_CONFIG", string(""));

        if (bytes(deploymentConfig).length != 0) {
            string memory json = vm.readFile(deploymentConfig);
            expected.pool = json.readAddress(".aave.pool");
            expected.wrappedNativeToken = json.readAddress(".assets.wrappedNativeToken");
        } else if (vm.envOr("USE_ADDRESS_BOOK", true)) {
            AaveV3Addresses.Market memory market = AaveV3Addresses.get(block.chainid);
            expected.pool = market.pool;
            expected.wrappedNativeToken = market.wrappedNativeToken;
        } else {
            expected.pool = vm.envAddress("AAVE_POOL");
            expected.wrappedNativeToken = vm.envAddress("WRAPPED_NATIVE_TOKEN");
        }
    }

    function verify(ExpectedDeployment memory expected) public view {
        AaveSupplyManager manager = AaveSupplyManager(payable(expected.manager));

        _assertAddress("pool", expected.pool, address(manager.pool()));
        _assertAddress("wrappedNativeToken", expected.wrappedNativeToken, address(manager.wrappedNativeToken()));
        _assertAddress("owner", expected.owner, manager.owner());
        _assertBool("paused", expected.paused, manager.paused());

        address pendingOwner = manager.pendingOwner();
        if (pendingOwner != address(0)) revert PendingOwnerSet(pendingOwner);

        console2.log("deployment verified", expected.manager);
        console2.log("pool", expected.pool);
        console2.log("wrappedNativeToken", expected.wrappedNativeToken);
        console2.log("owner", expected.owner);
        console2.log("paused", expected.paused);
    }

    function _assertAddress(string memory field, address expected, address actual) private pure {
        if (expected != actual) revert DeploymentMismatch(field, expected, actual);
    }

    function _assertBool(string memory field, bool expected, bool actual) private pure {
        if (expected != actual) revert DeploymentBoolMismatch(field, expected, actual);
    }
}
