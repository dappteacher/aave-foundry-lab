// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AaveOracleLens} from "../../src/AaveOracleLens.sol";
import {AavePositionLens} from "../../src/AavePositionLens.sol";
import {AaveSupplyManager} from "../../src/AaveSupplyManager.sol";
import {IERC20} from "../../src/interfaces/IERC20.sol";
import {AaveV3Addresses} from "../../src/libraries/AaveV3Addresses.sol";

contract AaveSupplyManagerForkTest is Test {
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
        AaveV3Addresses.Market memory market = AaveV3Addresses.ethereum();
        AaveSupplyManager manager = new AaveSupplyManager(market.pool, market.wrappedNativeToken, owner);
        AavePositionLens lens = new AavePositionLens(market.pool);
        AaveOracleLens oracleLens = new AaveOracleLens(market.oracle);

        deal(market.wrappedNativeToken, address(manager), amount);

        vm.prank(owner);
        manager.supplyToken(market.wrappedNativeToken, amount, 0);

        assertEq(IERC20(market.wrappedNativeToken).balanceOf(address(manager)), 0);
        assertApproxEqAbs(IERC20(market.wrappedNativeAToken).balanceOf(address(manager)), amount, 2);

        AavePositionLens.AccountData memory data = lens.getAccountData(address(manager));
        assertGt(data.totalCollateralBase, 0);
        assertEq(data.totalDebtBase, 0);

        uint256 wethPrice = oracleLens.getAssetPrice(market.wrappedNativeToken);
        uint256 suppliedValue = oracleLens.getAssetValue(market.wrappedNativeToken, amount, 1 ether);
        assertGt(wethPrice, 0);
        assertGt(suppliedValue, 0);

        vm.prank(owner);
        uint256 withdrawn = manager.withdrawToken(market.wrappedNativeToken, type(uint256).max, recipient);

        assertApproxEqAbs(withdrawn, amount, 2);
        assertApproxEqAbs(IERC20(market.wrappedNativeToken).balanceOf(recipient), amount, 2);
        assertLe(IERC20(market.wrappedNativeAToken).balanceOf(address(manager)), 2);
    }
}
