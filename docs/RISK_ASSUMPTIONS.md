# Slippage, Price, and Risk Assumptions

Date: 2026-05-24

## Scope

This project integrates with Aave V3 Pool and Oracle contracts. It does not execute swaps, route orders, or perform AMM interactions, so classic swap slippage is not part of the current execution path.

The relevant assumptions are instead about:

- Aave account risk and health factor
- Aave oracle prices and base currency units
- Token decimals used for value estimates
- Aave Pool accounting for supply, withdraw, borrow, and repay

## Slippage Assumptions

- `AaveSupplyManager` does not perform swaps, so no `amountOutMin` or price-impact parameter exists.
- `supplyToken`, `supplyNative`, `borrowToken`, `repayToken`, and `withdrawToken` delegate accounting to Aave V3.
- Aave `withdraw` and `repay` can return less than the requested amount when `type(uint256).max` or an amount above the available balance/debt is used. Tests cover capped return behavior through the local mock.

## Price Assumptions

- `AaveOracleLens` reads prices from Aave's configured oracle for the target market.
- Prices are assumed to be denominated in `BASE_CURRENCY` and scaled by `BASE_CURRENCY_UNIT`.
- `AaveOracleLens` treats a zero price as invalid and reverts.
- Portfolio value estimates require an explicit `assetUnit`, such as `1e18` for WETH or `1e6` for USDC, so token decimal assumptions are visible at call sites.

## Risk Assumptions

- The manager owns the Aave position. Collateral and debt are tracked against the manager contract.
- Borrowing is allowed only when the post-borrow health factor is greater than or equal to `minimumHealthFactor`.
- The health-factor check depends on Aave Pool data after the borrow call. If the health factor is below the requested threshold, the transaction reverts and the borrow state rolls back.
- Pausing blocks supply, borrow, and repay. Withdraw and rescue remain available so the owner can reduce exposure during an incident.

## Tests Covering These Assumptions

- Fuzz tests cover withdraw capping, repay capping, and post-borrow health-factor thresholds.
- Invariant tests exercise repeated supply, withdraw, borrow, and repay flows and assert local accounting remains consistent.
- Fork tests optionally verify real Aave V3 supply, withdraw, oracle reads, borrow, and repay behavior when `MAINNET_RPC_URL` is configured.

## Production Notes

- A production system should monitor health factor continuously off-chain.
- A production system should define minimum health-factor policies per asset and market.
- Oracle freshness and circuit-breaker behavior should be monitored externally.
- Any future swap integration must add explicit slippage controls and tests.
