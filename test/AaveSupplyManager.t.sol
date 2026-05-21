// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AaveSupplyManager} from "../src/AaveSupplyManager.sol";
import {MockAaveV3Pool} from "./mocks/MockAaveV3Pool.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockWETH} from "./mocks/MockWETH.sol";

contract AaveSupplyManagerTest is Test {
    AaveSupplyManager private manager;
    MockAaveV3Pool private pool;
    MockERC20 private usdc;
    MockWETH private weth;

    address private owner = address(0xA11CE);
    address private recipient = address(0xB0B);

    function setUp() public {
        pool = new MockAaveV3Pool();
        usdc = new MockERC20("USD Coin", "USDC", 6);
        weth = new MockWETH();
        manager = new AaveSupplyManager(address(pool), address(weth), owner);
    }

    function testSupplyTokenDepositsManagerBalanceIntoAave() public {
        uint256 amount = 1_000e6;
        usdc.mint(address(manager), amount);

        vm.prank(owner);
        manager.supplyToken(address(usdc), amount, 42);

        assertEq(pool.supplied(address(usdc), address(manager)), amount);
        assertEq(usdc.balanceOf(address(pool)), amount);
        assertEq(pool.lastAsset(), address(usdc));
        assertEq(pool.lastOnBehalfOf(), address(manager));
        assertEq(pool.lastReferralCode(), 42);
    }

    function testSupplyNativeWrapsAndSuppliesWeth() public {
        uint256 amount = 2 ether;
        vm.deal(owner, amount);

        vm.prank(owner);
        manager.supplyNative{value: amount}(0);

        assertEq(pool.supplied(address(weth), address(manager)), amount);
        assertEq(weth.balanceOf(address(pool)), amount);
    }

    function testWithdrawTokenSendsUnderlyingToRecipient() public {
        uint256 amount = 750e6;
        usdc.mint(address(manager), amount);

        vm.startPrank(owner);
        manager.supplyToken(address(usdc), amount, 0);
        uint256 withdrawn = manager.withdrawToken(address(usdc), 250e6, recipient);
        vm.stopPrank();

        assertEq(withdrawn, 250e6);
        assertEq(usdc.balanceOf(recipient), 250e6);
        assertEq(pool.supplied(address(usdc), address(manager)), 500e6);
    }

    function testOnlyOwnerCanSupply() public {
        usdc.mint(address(manager), 1e6);

        vm.expectRevert(AaveSupplyManager.NotOwner.selector);
        manager.supplyToken(address(usdc), 1e6, 0);
    }

    function testOwnerCanRescueIdleTokens() public {
        usdc.mint(address(manager), 100e6);

        vm.prank(owner);
        manager.rescueToken(address(usdc), 25e6, recipient);

        assertEq(usdc.balanceOf(recipient), 25e6);
        assertEq(usdc.balanceOf(address(manager)), 75e6);
    }
}
