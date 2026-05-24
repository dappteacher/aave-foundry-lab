// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAaveOracle {
    function BASE_CURRENCY() external view returns (address);
    function BASE_CURRENCY_UNIT() external view returns (uint256);
    function getAssetPrice(address asset) external view returns (uint256);
    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);
    function getSourceOfAsset(address asset) external view returns (address);
}
