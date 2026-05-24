// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "../../src/interfaces/IERC20.sol";

contract MockAaveV3Pool {
    struct AccountData {
        uint256 totalCollateralBase;
        uint256 totalDebtBase;
        uint256 availableBorrowsBase;
        uint256 currentLiquidationThreshold;
        uint256 ltv;
        uint256 healthFactor;
    }

    mapping(address => mapping(address => uint256)) public supplied;
    mapping(address => mapping(address => uint256)) public borrowed;
    mapping(address => AccountData) private accountData;

    address public lastAsset;
    uint256 public lastAmount;
    address public lastOnBehalfOf;
    uint16 public lastReferralCode;
    uint256 public lastInterestRateMode;

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external {
        IERC20(asset).transferFrom(msg.sender, address(this), amount);

        supplied[asset][onBehalfOf] += amount;
        lastAsset = asset;
        lastAmount = amount;
        lastOnBehalfOf = onBehalfOf;
        lastReferralCode = referralCode;
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        uint256 available = supplied[asset][msg.sender];
        uint256 withdrawn = amount == type(uint256).max || amount > available ? available : amount;

        supplied[asset][msg.sender] = available - withdrawn;
        IERC20(asset).transfer(to, withdrawn);

        return withdrawn;
    }

    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf)
        external
    {
        borrowed[asset][onBehalfOf] += amount;
        lastAsset = asset;
        lastAmount = amount;
        lastOnBehalfOf = onBehalfOf;
        lastReferralCode = referralCode;
        lastInterestRateMode = interestRateMode;

        IERC20(asset).transfer(msg.sender, amount);
    }

    function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf)
        external
        returns (uint256)
    {
        uint256 debt = borrowed[asset][onBehalfOf];
        uint256 repaid = amount == type(uint256).max || amount > debt ? debt : amount;

        borrowed[asset][onBehalfOf] = debt - repaid;
        lastAsset = asset;
        lastAmount = amount;
        lastOnBehalfOf = onBehalfOf;
        lastInterestRateMode = interestRateMode;

        IERC20(asset).transferFrom(msg.sender, address(this), repaid);

        return repaid;
    }

    function setUserAccountData(
        address user,
        uint256 totalCollateralBase,
        uint256 totalDebtBase,
        uint256 availableBorrowsBase,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    ) external {
        accountData[user] = AccountData({
            totalCollateralBase: totalCollateralBase,
            totalDebtBase: totalDebtBase,
            availableBorrowsBase: availableBorrowsBase,
            currentLiquidationThreshold: currentLiquidationThreshold,
            ltv: ltv,
            healthFactor: healthFactor
        });
    }

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        AccountData memory data = accountData[user];
        return (
            data.totalCollateralBase,
            data.totalDebtBase,
            data.availableBorrowsBase,
            data.currentLiquidationThreshold,
            data.ltv,
            data.healthFactor
        );
    }
}
