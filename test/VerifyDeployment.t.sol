// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {VerifyDeployment} from "../script/VerifyDeployment.s.sol";
import {AaveSupplyManager} from "../src/AaveSupplyManager.sol";
import {MockAaveV3Pool} from "./mocks/MockAaveV3Pool.sol";
import {MockWETH} from "./mocks/MockWETH.sol";

contract VerifyDeploymentTest is Test {
    VerifyDeployment private verifier;
    AaveSupplyManager private manager;
    MockAaveV3Pool private pool;
    MockWETH private weth;

    address private owner = address(0xA11CE);

    function setUp() public {
        verifier = new VerifyDeployment();
        pool = new MockAaveV3Pool();
        weth = new MockWETH();
        manager = new AaveSupplyManager(address(pool), address(weth), owner);
    }

    function testVerifyAcceptsExpectedDeployment() public view {
        verifier.verify(
            VerifyDeployment.ExpectedDeployment({
                manager: address(manager),
                pool: address(pool),
                wrappedNativeToken: address(weth),
                owner: owner,
                paused: false
            })
        );
    }

    function testVerifyRejectsWrongPool() public {
        address wrongPool = address(0xBAD);

        vm.expectRevert(
            abi.encodeWithSelector(VerifyDeployment.DeploymentMismatch.selector, "pool", wrongPool, address(pool))
        );
        verifier.verify(
            VerifyDeployment.ExpectedDeployment({
                manager: address(manager),
                pool: wrongPool,
                wrappedNativeToken: address(weth),
                owner: owner,
                paused: false
            })
        );
    }

    function testVerifyRejectsUnexpectedPauseState() public {
        vm.prank(owner);
        manager.pause();

        vm.expectRevert(abi.encodeWithSelector(VerifyDeployment.DeploymentBoolMismatch.selector, "paused", false, true));
        verifier.verify(
            VerifyDeployment.ExpectedDeployment({
                manager: address(manager),
                pool: address(pool),
                wrappedNativeToken: address(weth),
                owner: owner,
                paused: false
            })
        );
    }

    function testVerifyRejectsPendingOwner() public {
        address newOwner = address(0xC0FFEE);

        vm.prank(owner);
        manager.transferOwnership(newOwner);

        vm.expectRevert(abi.encodeWithSelector(VerifyDeployment.PendingOwnerSet.selector, newOwner));
        verifier.verify(
            VerifyDeployment.ExpectedDeployment({
                manager: address(manager),
                pool: address(pool),
                wrappedNativeToken: address(weth),
                owner: owner,
                paused: false
            })
        );
    }
}
