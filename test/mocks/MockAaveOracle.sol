// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockAaveOracle {
    address public immutable BASE_CURRENCY;
    uint256 public immutable BASE_CURRENCY_UNIT;

    mapping(address => uint256) private prices;
    mapping(address => address) private sources;

    constructor(address baseCurrency_, uint256 baseCurrencyUnit_) {
        BASE_CURRENCY = baseCurrency_;
        BASE_CURRENCY_UNIT = baseCurrencyUnit_;
    }

    function setAssetPrice(address asset, uint256 price) external {
        prices[asset] = price;
    }

    function setSourceOfAsset(address asset, address source) external {
        sources[asset] = source;
    }

    function getAssetPrice(address asset) external view returns (uint256) {
        return prices[asset];
    }

    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory assetPrices) {
        assetPrices = new uint256[](assets.length);

        for (uint256 i = 0; i < assets.length; i++) {
            assetPrices[i] = prices[assets[i]];
        }
    }

    function getSourceOfAsset(address asset) external view returns (address) {
        return sources[asset];
    }
}
