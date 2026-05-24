// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AaveSupplyManager} from "../../src/AaveSupplyManager.sol";
import {MockAaveV3Pool} from "../mocks/MockAaveV3Pool.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {MockNoReturnERC20} from "../mocks/MockNoReturnERC20.sol";
import {MockWETH} from "../mocks/MockWETH.sol";

contract AaveSupplyManagerSecurityTest is Test {
    AaveSupplyManager private manager;
    MockAaveV3Pool private pool;
    MockERC20 private usdc;
    MockWETH private weth;

    address private owner = address(0xA11CE);
    address private attacker = address(0xBAD);
    address private recipient = address(0xB0B);

    function setUp() public {
        pool = new MockAaveV3Pool();
        usdc = new MockERC20("USD Coin", "USDC", 6);
        weth = new MockWETH();
        manager = new AaveSupplyManager(address(pool), address(weth), owner);
    }

    function testConstructorRejectsZeroAddresses() public {
        vm.expectRevert(AaveSupplyManager.ZeroAddress.selector);
        new AaveSupplyManager(address(0), address(weth), owner);

        vm.expectRevert(AaveSupplyManager.ZeroAddress.selector);
        new AaveSupplyManager(address(pool), address(0), owner);

        vm.expectRevert(AaveSupplyManager.ZeroAddress.selector);
        new AaveSupplyManager(address(pool), address(weth), address(0));
    }

    function testOwnershipTransferRejectsZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(AaveSupplyManager.ZeroAddress.selector);
        manager.transferOwnership(address(0));
    }

    function testOnlyOwnerCanWithdrawRepayRescueAndTransferOwnership() public {
        uint256 rateMode = manager.VARIABLE_INTEREST_RATE_MODE();

        vm.startPrank(attacker);

        vm.expectRevert(AaveSupplyManager.NotOwner.selector);
        manager.withdrawToken(address(usdc), 1, recipient);

        vm.expectRevert(AaveSupplyManager.NotOwner.selector);
        manager.repayToken(address(usdc), 1, rateMode);

        vm.expectRevert(AaveSupplyManager.NotOwner.selector);
        manager.rescueToken(address(usdc), 1, recipient);

        vm.expectRevert(AaveSupplyManager.NotOwner.selector);
        manager.transferOwnership(attacker);

        vm.expectRevert(AaveSupplyManager.NotOwner.selector);
        manager.pause();

        vm.expectRevert(AaveSupplyManager.NotOwner.selector);
        manager.unpause();

        vm.stopPrank();
    }

    function testOnlyPendingOwnerCanAcceptOwnership() public {
        address newOwner = address(0xC0FFEE);

        vm.prank(owner);
        manager.transferOwnership(newOwner);

        vm.prank(attacker);
        vm.expectRevert(AaveSupplyManager.NotOwner.selector);
        manager.acceptOwnership();

        assertEq(manager.owner(), owner);
    }

    function testPauseBlocksRiskIncreasingActionsButAllowsEmergencyWithdrawal() public {
        uint256 amount = 1_000e6;
        uint256 rateMode = manager.VARIABLE_INTEREST_RATE_MODE();
        usdc.mint(address(manager), amount);
        vm.deal(owner, 1 ether);

        vm.prank(owner);
        manager.pause();

        vm.startPrank(owner);

        vm.expectRevert(AaveSupplyManager.EnforcedPause.selector);
        manager.supplyToken(address(usdc), amount, 0);

        vm.expectRevert(AaveSupplyManager.EnforcedPause.selector);
        manager.supplyNative{value: 1 ether}(0);

        vm.expectRevert(AaveSupplyManager.EnforcedPause.selector);
        manager.borrowVariableToken(address(usdc), 1, 0, recipient, 1.1e18);

        vm.expectRevert(AaveSupplyManager.EnforcedPause.selector);
        manager.repayToken(address(usdc), 1, rateMode);

        uint256 rescuedBefore = usdc.balanceOf(recipient);
        manager.rescueToken(address(usdc), amount, recipient);

        vm.stopPrank();

        assertEq(usdc.balanceOf(recipient) - rescuedBefore, amount);
    }

    function testUnpauseRestoresActions() public {
        uint256 amount = 1_000e6;
        usdc.mint(address(manager), amount);

        vm.startPrank(owner);
        manager.pause();
        manager.unpause();
        manager.supplyToken(address(usdc), amount, 0);
        vm.stopPrank();

        assertEq(pool.supplied(address(usdc), address(manager)), amount);
    }

    function testSafeTransferSupportsTokensWithNoReturnValue() public {
        MockNoReturnERC20 noReturnToken = new MockNoReturnERC20("No Return", "NORET", 18);
        uint256 amount = 10 ether;
        noReturnToken.mint(address(manager), amount);

        vm.prank(owner);
        manager.rescueToken(address(noReturnToken), amount, recipient);

        assertEq(noReturnToken.balanceOf(recipient), amount);
    }

    function testActionFunctionsRejectZeroAmounts() public {
        uint256 rateMode = manager.VARIABLE_INTEREST_RATE_MODE();

        vm.startPrank(owner);

        vm.expectRevert(AaveSupplyManager.ZeroAmount.selector);
        manager.supplyToken(address(usdc), 0, 0);

        vm.expectRevert(AaveSupplyManager.ZeroAmount.selector);
        manager.supplyNative{value: 0}(0);

        vm.expectRevert(AaveSupplyManager.ZeroAmount.selector);
        manager.withdrawToken(address(usdc), 0, recipient);

        vm.expectRevert(AaveSupplyManager.ZeroAmount.selector);
        manager.borrowVariableToken(address(usdc), 0, 0, recipient, 1.1e18);

        vm.expectRevert(AaveSupplyManager.ZeroAmount.selector);
        manager.repayToken(address(usdc), 0, rateMode);

        vm.expectRevert(AaveSupplyManager.ZeroAmount.selector);
        manager.rescueToken(address(usdc), 0, recipient);

        vm.stopPrank();
    }

    function testUnhealthyBorrowRollsBackDebtAndRecipientTransfer() public {
        uint256 amount = 500e6;
        usdc.mint(address(pool), amount);
        pool.setUserAccountData(address(manager), 1_000e8, 900e8, 0, 8_250, 7_500, 1.01e18);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(AaveSupplyManager.UnhealthyPosition.selector, 1.01e18, 1.2e18));
        manager.borrowVariableToken(address(usdc), amount, 0, recipient, 1.2e18);

        assertEq(pool.borrowed(address(usdc), address(manager)), 0);
        assertEq(usdc.balanceOf(recipient), 0);
    }
}
