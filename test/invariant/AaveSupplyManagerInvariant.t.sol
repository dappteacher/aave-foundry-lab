// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";
import {AaveSupplyManager} from "../../src/AaveSupplyManager.sol";
import {MockAaveV3Pool} from "../mocks/MockAaveV3Pool.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {MockWETH} from "../mocks/MockWETH.sol";

contract AaveSupplyManagerHandler is Test {
    AaveSupplyManager public manager;
    MockAaveV3Pool public pool;
    MockERC20 public usdc;

    address public owner;
    address public recipient = address(0xB0B);

    uint256 public ghostSupplied;
    uint256 public ghostWithdrawn;
    uint256 public ghostBorrowed;
    uint256 public ghostRepaid;

    constructor(AaveSupplyManager manager_, MockAaveV3Pool pool_, MockERC20 usdc_, address owner_) {
        manager = manager_;
        pool = pool_;
        usdc = usdc_;
        owner = owner_;
    }

    function supply(uint256 amount) external {
        amount = bound(amount, 1, 1_000_000e6);
        usdc.mint(address(manager), amount);

        vm.prank(owner);
        manager.supplyToken(address(usdc), amount, 0);

        ghostSupplied += amount;
    }

    function withdraw(uint256 amount) external {
        uint256 suppliedBalance = pool.supplied(address(usdc), address(manager));
        if (suppliedBalance == 0) return;

        amount = bound(amount, 1, suppliedBalance * 2);
        uint256 expectedWithdrawn = amount > suppliedBalance ? suppliedBalance : amount;

        vm.prank(owner);
        uint256 withdrawn = manager.withdrawToken(address(usdc), amount, recipient);

        ghostWithdrawn += withdrawn;
        assertEq(withdrawn, expectedWithdrawn);
    }

    function borrow(uint256 amount, uint256 healthFactor) external {
        amount = bound(amount, 1, 1_000_000e6);
        healthFactor = bound(healthFactor, 1.5e18, 5e18);

        usdc.mint(address(pool), amount);
        pool.setUserAccountData(address(manager), 10_000e8, 2_000e8, 4_000e8, 8_250, 7_500, healthFactor);

        vm.prank(owner);
        manager.borrowVariableToken(address(usdc), amount, 0, recipient, 1.5e18);

        ghostBorrowed += amount;
    }

    function repay(uint256 amount) external {
        uint256 debt = pool.borrowed(address(usdc), address(manager));
        if (debt == 0) return;

        amount = bound(amount, 1, debt * 2);
        uint256 expectedRepaid = amount > debt ? debt : amount;

        usdc.mint(address(manager), expectedRepaid);

        vm.prank(owner);
        uint256 repaid = manager.repayToken(address(usdc), amount, manager.VARIABLE_INTEREST_RATE_MODE());

        ghostRepaid += repaid;
        assertEq(repaid, expectedRepaid);
    }
}

contract AaveSupplyManagerInvariantTest is StdInvariant, Test {
    AaveSupplyManager private manager;
    MockAaveV3Pool private pool;
    MockERC20 private usdc;
    MockWETH private weth;
    AaveSupplyManagerHandler private handler;

    address private owner = address(0xA11CE);

    function setUp() public {
        pool = new MockAaveV3Pool();
        usdc = new MockERC20("USD Coin", "USDC", 6);
        weth = new MockWETH();
        manager = new AaveSupplyManager(address(pool), address(weth), owner);
        handler = new AaveSupplyManagerHandler(manager, pool, usdc, owner);

        targetContract(address(handler));
    }

    function invariant_suppliedAccountingMatchesGhostState() public view {
        assertEq(
            pool.supplied(address(usdc), address(manager)),
            handler.ghostSupplied() - handler.ghostWithdrawn(),
            "supplied accounting drift"
        );
    }

    function invariant_borrowedAccountingMatchesGhostState() public view {
        assertEq(
            pool.borrowed(address(usdc), address(manager)),
            handler.ghostBorrowed() - handler.ghostRepaid(),
            "borrowed accounting drift"
        );
    }

    function invariant_managerDoesNotKeepBorrowedUsdc() public view {
        assertEq(usdc.balanceOf(address(manager)), 0, "manager should not retain USDC");
    }
}
