// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AavePositionLens} from "../src/AavePositionLens.sol";
import {MockAaveV3Pool} from "./mocks/MockAaveV3Pool.sol";

contract AavePositionLensTest is Test {
    MockAaveV3Pool private pool;
    AavePositionLens private lens;

    address private user = address(0xCAFE);

    function setUp() public {
        pool = new MockAaveV3Pool();
        lens = new AavePositionLens(address(pool));
    }

    function testReadsAaveAccountData() public {
        pool.setUserAccountData({
            user: user,
            totalCollateralBase: 10_000e8,
            totalDebtBase: 2_500e8,
            availableBorrowsBase: 5_000e8,
            currentLiquidationThreshold: 8_250,
            ltv: 7_500,
            healthFactor: 3.3e18
        });

        AavePositionLens.AccountData memory data = lens.getAccountData(user);

        assertEq(data.totalCollateralBase, 10_000e8);
        assertEq(data.totalDebtBase, 2_500e8);
        assertEq(data.availableBorrowsBase, 5_000e8);
        assertEq(data.currentLiquidationThreshold, 8_250);
        assertEq(data.ltv, 7_500);
        assertEq(data.healthFactor, 3.3e18);
    }

    function testReportsHealthAgainstMinimum() public {
        pool.setUserAccountData(user, 1_000e8, 500e8, 250e8, 8_000, 7_000, 1.8e18);

        assertTrue(lens.isHealthy(user, 1.5e18));
        assertFalse(lens.isHealthy(user, 2e18));
    }

    function testRevertsForZeroUser() public {
        vm.expectRevert(AavePositionLens.ZeroAddress.selector);
        lens.getAccountData(address(0));
    }

    function testRevertsForZeroPool() public {
        vm.expectRevert(AavePositionLens.ZeroAddress.selector);
        new AavePositionLens(address(0));
    }
}
