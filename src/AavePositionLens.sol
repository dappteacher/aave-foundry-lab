// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IAaveV3Pool} from "./interfaces/IAaveV3Pool.sol";

/// @title AavePositionLens
/// @notice Read-only helper for inspecting Aave V3 account risk metrics.
contract AavePositionLens {
    IAaveV3Pool public immutable pool;

    struct AccountData {
        uint256 totalCollateralBase;
        uint256 totalDebtBase;
        uint256 availableBorrowsBase;
        uint256 currentLiquidationThreshold;
        uint256 ltv;
        uint256 healthFactor;
    }

    error ZeroAddress();

    constructor(address pool_) {
        if (pool_ == address(0)) revert ZeroAddress();
        pool = IAaveV3Pool(pool_);
    }

    function getAccountData(address user) public view returns (AccountData memory data) {
        if (user == address(0)) revert ZeroAddress();

        (
            data.totalCollateralBase,
            data.totalDebtBase,
            data.availableBorrowsBase,
            data.currentLiquidationThreshold,
            data.ltv,
            data.healthFactor
        ) = pool.getUserAccountData(user);
    }

    function isHealthy(address user, uint256 minimumHealthFactor) external view returns (bool) {
        AccountData memory data = getAccountData(user);
        return data.healthFactor >= minimumHealthFactor;
    }
}
