// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IAaveV3Pool} from "./interfaces/IAaveV3Pool.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {SafeERC20} from "./libraries/SafeERC20.sol";

/// @title AaveSupplyManager
/// @notice Minimal owner-controlled treasury adapter for supplying assets to Aave V3.
contract AaveSupplyManager {
    using SafeERC20 for IERC20;

    uint256 public constant VARIABLE_INTEREST_RATE_MODE = 2;

    IAaveV3Pool public immutable pool;
    IWETH public immutable wrappedNativeToken;
    address public owner;
    address public pendingOwner;
    bool public paused;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferStarted(address indexed previousOwner, address indexed pendingOwner);
    event Paused(address indexed account);
    event Unpaused(address indexed account);
    event Supplied(address indexed asset, uint256 amount, uint16 referralCode);
    event NativeSupplied(uint256 amount, uint16 referralCode);
    event Withdrawn(address indexed asset, uint256 requestedAmount, uint256 withdrawnAmount, address indexed recipient);
    event Borrowed(
        address indexed asset,
        uint256 amount,
        uint256 interestRateMode,
        address indexed recipient,
        uint256 healthFactorAfterBorrow
    );
    event Repaid(address indexed asset, uint256 requestedAmount, uint256 repaidAmount, uint256 interestRateMode);
    event TokenRescued(address indexed token, uint256 amount, address indexed recipient);

    error NotOwner();
    error ZeroAddress();
    error ZeroAmount();
    error EnforcedPause();
    error UnhealthyPosition(uint256 healthFactor, uint256 minimumHealthFactor);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert EnforcedPause();
        _;
    }

    constructor(address pool_, address wrappedNativeToken_, address owner_) {
        if (pool_ == address(0) || wrappedNativeToken_ == address(0) || owner_ == address(0)) {
            revert ZeroAddress();
        }

        pool = IAaveV3Pool(pool_);
        wrappedNativeToken = IWETH(wrappedNativeToken_);
        owner = owner_;

        emit OwnershipTransferred(address(0), owner_);
    }

    receive() external payable {}

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();

        pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner, newOwner);
    }

    function acceptOwnership() external {
        if (msg.sender != pendingOwner) revert NotOwner();

        address previousOwner = owner;
        owner = pendingOwner;
        pendingOwner = address(0);

        emit OwnershipTransferred(previousOwner, owner);
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function supplyToken(address asset, uint256 amount, uint16 referralCode) external onlyOwner whenNotPaused {
        if (asset == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        _approveExact(asset, address(pool), amount);
        pool.supply(asset, amount, address(this), referralCode);

        emit Supplied(asset, amount, referralCode);
    }

    function supplyNative(uint16 referralCode) external payable onlyOwner whenNotPaused {
        if (msg.value == 0) revert ZeroAmount();

        wrappedNativeToken.deposit{value: msg.value}();
        _approveExact(address(wrappedNativeToken), address(pool), msg.value);
        pool.supply(address(wrappedNativeToken), msg.value, address(this), referralCode);

        emit NativeSupplied(msg.value, referralCode);
    }

    function withdrawToken(address asset, uint256 amount, address recipient)
        external
        onlyOwner
        returns (uint256 withdrawn)
    {
        if (asset == address(0) || recipient == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        withdrawn = pool.withdraw(asset, amount, recipient);

        emit Withdrawn(asset, amount, withdrawn, recipient);
    }

    function borrowToken(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address recipient,
        uint256 minimumHealthFactor
    ) external onlyOwner whenNotPaused {
        _borrowToken(asset, amount, interestRateMode, referralCode, recipient, minimumHealthFactor);
    }

    function borrowVariableToken(
        address asset,
        uint256 amount,
        uint16 referralCode,
        address recipient,
        uint256 minimumHealthFactor
    ) external onlyOwner whenNotPaused {
        _borrowToken(asset, amount, VARIABLE_INTEREST_RATE_MODE, referralCode, recipient, minimumHealthFactor);
    }

    function repayToken(address asset, uint256 amount, uint256 interestRateMode)
        external
        onlyOwner
        whenNotPaused
        returns (uint256 repaid)
    {
        if (asset == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        _approveExact(asset, address(pool), amount);
        repaid = pool.repay(asset, amount, interestRateMode, address(this));

        emit Repaid(asset, amount, repaid, interestRateMode);
    }

    function rescueToken(address token, uint256 amount, address recipient) external onlyOwner {
        if (token == address(0) || recipient == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        IERC20(token).safeTransfer(recipient, amount);

        emit TokenRescued(token, amount, recipient);
    }

    function _approveExact(address token, address spender, uint256 amount) private {
        IERC20 erc20 = IERC20(token);
        erc20.safeApprove(spender, 0);
        erc20.safeApprove(spender, amount);
    }

    function _borrowToken(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address recipient,
        uint256 minimumHealthFactor
    ) private {
        if (asset == address(0) || recipient == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        pool.borrow(asset, amount, interestRateMode, referralCode, address(this));

        uint256 healthFactor = _healthFactor();
        if (healthFactor < minimumHealthFactor) {
            revert UnhealthyPosition(healthFactor, minimumHealthFactor);
        }

        IERC20(asset).safeTransfer(recipient, amount);

        emit Borrowed(asset, amount, interestRateMode, recipient, healthFactor);
    }

    function _healthFactor() private view returns (uint256 healthFactor) {
        (,,,,, healthFactor) = pool.getUserAccountData(address(this));
    }
}
