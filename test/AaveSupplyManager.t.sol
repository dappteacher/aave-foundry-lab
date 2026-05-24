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

    function testBorrowVariableTokenSendsDebtAssetToRecipientWhenHealthy() public {
        uint256 amount = 500e6;
        usdc.mint(address(pool), amount);
        pool.setUserAccountData(address(manager), 10_000e8, 2_000e8, 4_000e8, 8_250, 7_500, 2e18);

        vm.prank(owner);
        manager.borrowVariableToken(address(usdc), amount, 7, recipient, 1.5e18);

        assertEq(usdc.balanceOf(recipient), amount);
        assertEq(pool.borrowed(address(usdc), address(manager)), amount);
        assertEq(pool.lastAsset(), address(usdc));
        assertEq(pool.lastOnBehalfOf(), address(manager));
        assertEq(pool.lastReferralCode(), 7);
        assertEq(pool.lastInterestRateMode(), manager.VARIABLE_INTEREST_RATE_MODE());
    }

    function testBorrowTokenRevertsWhenHealthFactorIsTooLow() public {
        uint256 amount = 500e6;
        usdc.mint(address(pool), amount);
        pool.setUserAccountData(address(manager), 10_000e8, 7_000e8, 0, 8_250, 7_500, 1.1e18);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(AaveSupplyManager.UnhealthyPosition.selector, 1.1e18, 1.5e18));
        manager.borrowToken(address(usdc), amount, 2, 0, recipient, 1.5e18);

        assertEq(usdc.balanceOf(recipient), 0);
        assertEq(pool.borrowed(address(usdc), address(manager)), 0);
    }

    function testRepayTokenReturnsAmountRepaid() public {
        uint256 borrowAmount = 500e6;
        uint256 repayAmount = 200e6;
        uint256 rateMode = manager.VARIABLE_INTEREST_RATE_MODE();
        usdc.mint(address(pool), borrowAmount);
        pool.setUserAccountData(address(manager), 10_000e8, 2_000e8, 4_000e8, 8_250, 7_500, 2e18);

        vm.prank(owner);
        manager.borrowVariableToken(address(usdc), borrowAmount, 0, recipient, 1.5e18);

        usdc.mint(address(manager), repayAmount);

        vm.prank(owner);
        uint256 repaid = manager.repayToken(address(usdc), repayAmount, rateMode);

        assertEq(repaid, repayAmount);
        assertEq(pool.borrowed(address(usdc), address(manager)), borrowAmount - repayAmount);
        assertEq(usdc.balanceOf(address(pool)), repayAmount);
    }

    function testOnlyOwnerCanSupply() public {
        usdc.mint(address(manager), 1e6);

        vm.expectRevert(AaveSupplyManager.NotOwner.selector);
        manager.supplyToken(address(usdc), 1e6, 0);
    }

    function testOnlyOwnerCanBorrow() public {
        usdc.mint(address(pool), 1e6);
        pool.setUserAccountData(address(manager), 1_000e8, 100e8, 500e8, 8_000, 7_000, 2e18);

        vm.expectRevert(AaveSupplyManager.NotOwner.selector);
        manager.borrowVariableToken(address(usdc), 1e6, 0, recipient, 1.5e18);
    }

    function testOwnerCanRescueIdleTokens() public {
        usdc.mint(address(manager), 100e6);

        vm.prank(owner);
        manager.rescueToken(address(usdc), 25e6, recipient);

        assertEq(usdc.balanceOf(recipient), 25e6);
        assertEq(usdc.balanceOf(address(manager)), 75e6);
    }
}
