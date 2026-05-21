// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AaveSupplyManager} from "../../src/AaveSupplyManager.sol";
import {IERC20} from "../../src/interfaces/IERC20.sol";

contract AaveSupplyManagerForkTest is Test {
    address private constant AAVE_V3_ETHEREUM_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant A_ETH_WETH = 0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8;

    address private owner = address(0xA11CE);
    address private recipient = address(0xB0B);

    modifier withMainnetFork() {
        string memory rpcUrl = vm.envOr("MAINNET_RPC_URL", string(""));
        if (bytes(rpcUrl).length == 0) {
            emit log("MAINNET_RPC_URL not set; skipping mainnet fork integration test");
            return;
        }

        vm.createSelectFork(rpcUrl);
        _;
    }

    function testSupplyAndWithdrawWethOnAaveV3EthereumFork() public withMainnetFork {
        uint256 amount = 1 ether;
        AaveSupplyManager manager = new AaveSupplyManager(AAVE_V3_ETHEREUM_POOL, WETH, owner);

        deal(WETH, address(manager), amount);

        vm.prank(owner);
        manager.supplyToken(WETH, amount, 0);

        assertEq(IERC20(WETH).balanceOf(address(manager)), 0);
        assertApproxEqAbs(IERC20(A_ETH_WETH).balanceOf(address(manager)), amount, 2);

        vm.prank(owner);
        uint256 withdrawn = manager.withdrawToken(WETH, type(uint256).max, recipient);

        assertApproxEqAbs(withdrawn, amount, 2);
        assertApproxEqAbs(IERC20(WETH).balanceOf(recipient), amount, 2);
        assertLe(IERC20(A_ETH_WETH).balanceOf(address(manager)), 2);
    }
}
