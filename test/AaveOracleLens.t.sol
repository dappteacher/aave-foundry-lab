// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AaveOracleLens} from "../src/AaveOracleLens.sol";
import {MockAaveOracle} from "./mocks/MockAaveOracle.sol";

contract AaveOracleLensTest is Test {
    MockAaveOracle private oracle;
    AaveOracleLens private lens;

    address private weth = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address private usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address private ethUsdSource = address(0x1234);
    address private usdBaseCurrency = address(0x0);

    function setUp() public {
        oracle = new MockAaveOracle(usdBaseCurrency, 1e8);
        lens = new AaveOracleLens(address(oracle));

        oracle.setAssetPrice(weth, 3_000e8);
        oracle.setAssetPrice(usdc, 1e8);
        oracle.setSourceOfAsset(weth, ethUsdSource);
    }

    function testReturnsBaseCurrency() public view {
        (address currency, uint256 unit) = lens.baseCurrency();

        assertEq(currency, usdBaseCurrency);
        assertEq(unit, 1e8);
    }

    function testReturnsAssetPriceWithSource() public view {
        AaveOracleLens.AssetPrice memory assetPrice = lens.getAssetPriceWithSource(weth);

        assertEq(assetPrice.asset, weth);
        assertEq(assetPrice.price, 3_000e8);
        assertEq(assetPrice.source, ethUsdSource);
    }

    function testReturnsBatchPrices() public view {
        address[] memory assets = new address[](2);
        assets[0] = weth;
        assets[1] = usdc;

        uint256[] memory prices = lens.getAssetsPrices(assets);

        assertEq(prices[0], 3_000e8);
        assertEq(prices[1], 1e8);
    }

    function testCalculatesAssetValueInBaseCurrency() public view {
        uint256 value = lens.getAssetValue(weth, 2 ether, 1 ether);

        assertEq(value, 6_000e8);
    }

    function testCalculatesPortfolioValueInBaseCurrency() public view {
        address[] memory assets = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        uint256[] memory assetUnits = new uint256[](2);

        assets[0] = weth;
        assets[1] = usdc;
        amounts[0] = 1 ether;
        amounts[1] = 500e6;
        assetUnits[0] = 1 ether;
        assetUnits[1] = 1e6;

        uint256 value = lens.getPortfolioValue(assets, amounts, assetUnits);

        assertEq(value, 3_500e8);
    }

    function testRevertsForZeroPrice() public {
        address unknownAsset = address(0xDEAD);

        vm.expectRevert(abi.encodeWithSelector(AaveOracleLens.ZeroPrice.selector, unknownAsset));
        lens.getAssetPrice(unknownAsset);
    }

    function testRevertsForMismatchedPortfolioInputs() public {
        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](2);
        uint256[] memory assetUnits = new uint256[](1);

        assets[0] = weth;
        amounts[0] = 1 ether;
        amounts[1] = 1e6;
        assetUnits[0] = 1 ether;

        vm.expectRevert(AaveOracleLens.LengthMismatch.selector);
        lens.getPortfolioValue(assets, amounts, assetUnits);
    }

    function testRevertsForZeroOracle() public {
        vm.expectRevert(AaveOracleLens.ZeroAddress.selector);
        new AaveOracleLens(address(0));
    }
}
