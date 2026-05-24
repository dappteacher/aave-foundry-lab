// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AaveV3Addresses} from "../src/libraries/AaveV3Addresses.sol";

contract AaveV3AddressesHarness {
    function get(uint256 chainId) external pure returns (AaveV3Addresses.Market memory) {
        return AaveV3Addresses.get(chainId);
    }
}

contract AaveV3AddressesTest is Test {
    AaveV3AddressesHarness private harness = new AaveV3AddressesHarness();

    function testReturnsEthereumMarket() public pure {
        AaveV3Addresses.Market memory market = AaveV3Addresses.get(1);

        assertEq(market.pool, 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
        assertEq(market.oracle, 0x54586bE62E3c3580375aE3723C145253060Ca0C2);
        assertEq(market.wrappedNativeToken, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        assertEq(market.wrappedNativeAToken, 0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8);
        assertEq(market.usdc, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    }

    function testRevertsForUnsupportedChain() public {
        vm.expectRevert(abi.encodeWithSelector(AaveV3Addresses.UnsupportedChain.selector, 31337));
        harness.get(31337);
    }
}
