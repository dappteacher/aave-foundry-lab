// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {AavePositionLens} from "../src/AavePositionLens.sol";
import {AaveV3Addresses} from "../src/libraries/AaveV3Addresses.sol";

contract CheckAaveHealth is Script {
    using stdJson for string;

    function run() external {
        address manager = vm.envAddress("MANAGER");
        string memory deploymentConfig = vm.envOr("DEPLOYMENT_CONFIG", string(""));
        address pool;
        uint256 warningHealthFactor;
        uint256 criticalHealthFactor;

        if (bytes(deploymentConfig).length != 0) {
            string memory json = vm.readFile(deploymentConfig);
            pool = json.readAddress(".aave.pool");
            warningHealthFactor = json.readUint(".risk.warningHealthFactorWad");
            criticalHealthFactor = json.readUint(".risk.criticalHealthFactorWad");
        } else {
            AaveV3Addresses.Market memory market = AaveV3Addresses.get(block.chainid);
            pool = market.pool;
            warningHealthFactor = vm.envOr("WARNING_HEALTH_FACTOR_WAD", uint256(1.6e18));
            criticalHealthFactor = vm.envOr("CRITICAL_HEALTH_FACTOR_WAD", uint256(1.3e18));
        }

        AavePositionLens lens = new AavePositionLens(pool);
        AavePositionLens.AccountData memory data = lens.getAccountData(manager);

        console2.log("manager", manager);
        console2.log("pool", pool);
        console2.log("totalCollateralBase", data.totalCollateralBase);
        console2.log("totalDebtBase", data.totalDebtBase);
        console2.log("availableBorrowsBase", data.availableBorrowsBase);
        console2.log("currentLiquidationThreshold", data.currentLiquidationThreshold);
        console2.log("ltv", data.ltv);
        console2.log("healthFactor", data.healthFactor);
        console2.log("warningHealthFactor", warningHealthFactor);
        console2.log("criticalHealthFactor", criticalHealthFactor);

        if (data.totalDebtBase == 0) {
            console2.log("status", "NO_DEBT");
        } else if (data.healthFactor <= criticalHealthFactor) {
            console2.log("status", "CRITICAL");
        } else if (data.healthFactor <= warningHealthFactor) {
            console2.log("status", "WARNING");
        } else {
            console2.log("status", "HEALTHY");
        }
    }
}
