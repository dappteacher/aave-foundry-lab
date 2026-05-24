# Monitoring Strategy

Date: 2026-05-24

## Goals

The monitoring goal is to detect liquidation risk early enough for an operator or multisig to reduce debt, add collateral, pause risk-increasing operations, or withdraw idle assets.

Primary signals:

- Health factor
- Total collateral base
- Total debt base
- Available borrows base
- Current liquidation threshold
- LTV
- Oracle price movement for collateral and debt assets

## Thresholds

Each deployment config includes default thresholds:

- Target health factor: `2.0`
- Warning health factor: `1.6`
- Critical health factor: `1.3`

Operational policy:

- `HEALTHY`: health factor above warning threshold.
- `WARNING`: investigate, consider repaying debt or adding collateral.
- `CRITICAL`: pause risk-increasing actions and prepare immediate repayment or collateral top-up.
- `NO_DEBT`: no liquidation risk from debt, but collateral and oracle values should still be watched.

## Health Check Script

Use `script/CheckAaveHealth.s.sol` to read Aave account data for a deployed manager:

```shell
DEPLOYMENT_CONFIG=config/deployments/ethereum.json \
MANAGER=0xDeployedManager \
forge script script/CheckAaveHealth.s.sol:CheckAaveHealth \
  --rpc-url $MAINNET_RPC_URL
```

The script prints the manager account data and a status label: `NO_DEBT`, `HEALTHY`, `WARNING`, or `CRITICAL`.

## Suggested Production Monitoring Loop

- Run every 1 to 5 minutes while debt is open.
- Run immediately after every supply, borrow, repay, or withdraw transaction.
- Alert the operator and multisig signers on warning.
- Alert with paging severity on critical.
- Store historical health-factor values for trend detection.
- Monitor Aave governance and risk-parameter updates for listed collateral and debt assets.

## Emergency Response

When health factor reaches warning:

- Review current collateral and debt asset prices.
- Estimate repayment needed to return above target health factor.
- Consider adding collateral if the multisig has available assets.

When health factor reaches critical:

- Call `pause` to block new supply, borrow, and repay actions through this manager.
- Repay debt directly through the manager if assets are available.
- Transfer repayment assets to the manager, then call `repayToken`.
- Avoid withdrawing collateral until the debt position is safe.

## Limitations

- This repo provides a monitoring script and strategy, not a hosted monitoring service.
- Oracle freshness and cross-chain sequencer health should be monitored with dedicated infrastructure.
- Alerts should be implemented off-chain using the operator's preferred stack, such as GitHub Actions cron, Tenderly, OpenZeppelin Defender, Grafana, or a custom bot.
