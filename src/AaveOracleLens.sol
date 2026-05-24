// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IAaveOracle} from "./interfaces/IAaveOracle.sol";

/// @title AaveOracleLens
/// @notice Read-only helper for Aave oracle prices and base-currency value estimates.
contract AaveOracleLens {
    IAaveOracle public immutable oracle;

    struct AssetPrice {
        address asset;
        uint256 price;
        address source;
    }

    error EmptyAssets();
    error LengthMismatch();
    error ZeroAddress();
    error ZeroAmount();
    error ZeroAssetUnit();
    error ZeroPrice(address asset);

    constructor(address oracle_) {
        if (oracle_ == address(0)) revert ZeroAddress();
        oracle = IAaveOracle(oracle_);
    }

    function baseCurrency() external view returns (address currency, uint256 unit) {
        currency = oracle.BASE_CURRENCY();
        unit = oracle.BASE_CURRENCY_UNIT();
    }

    function getAssetPrice(address asset) public view returns (uint256 price) {
        if (asset == address(0)) revert ZeroAddress();

        price = oracle.getAssetPrice(asset);
        if (price == 0) revert ZeroPrice(asset);
    }

    function getAssetPriceWithSource(address asset) external view returns (AssetPrice memory assetPrice) {
        assetPrice = AssetPrice({asset: asset, price: getAssetPrice(asset), source: oracle.getSourceOfAsset(asset)});
    }

    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory prices) {
        if (assets.length == 0) revert EmptyAssets();

        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i] == address(0)) revert ZeroAddress();
        }

        prices = oracle.getAssetsPrices(assets);

        for (uint256 i = 0; i < prices.length; i++) {
            if (prices[i] == 0) revert ZeroPrice(assets[i]);
        }
    }

    function getAssetValue(address asset, uint256 amount, uint256 assetUnit) public view returns (uint256 value) {
        if (amount == 0) revert ZeroAmount();
        if (assetUnit == 0) revert ZeroAssetUnit();

        value = amount * getAssetPrice(asset) / assetUnit;
    }

    function getPortfolioValue(address[] calldata assets, uint256[] calldata amounts, uint256[] calldata assetUnits)
        external
        view
        returns (uint256 value)
    {
        if (assets.length == 0) revert EmptyAssets();
        if (assets.length != amounts.length || assets.length != assetUnits.length) revert LengthMismatch();

        for (uint256 i = 0; i < assets.length; i++) {
            value += getAssetValue(assets[i], amounts[i], assetUnits[i]);
        }
    }
}
