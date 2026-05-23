// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library AaveV3Addresses {
    uint256 internal constant ETHEREUM_CHAIN_ID = 1;

    struct Market {
        address pool;
        address wrappedNativeToken;
        address wrappedNativeAToken;
    }

    error UnsupportedChain(uint256 chainId);

    function get(uint256 chainId) internal pure returns (Market memory market) {
        if (chainId == ETHEREUM_CHAIN_ID) {
            return ethereum();
        }

        revert UnsupportedChain(chainId);
    }

    function ethereum() internal pure returns (Market memory market) {
        market = Market({
            pool: 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2,
            wrappedNativeToken: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            wrappedNativeAToken: 0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8
        });
    }
}
