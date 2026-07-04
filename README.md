# Aave Foundry Lab

Production-inspired Aave V3 integration project built with Foundry. This repository demonstrates how a Solidity treasury manager can supply collateral, borrow, repay, withdraw, read Aave account risk, query oracle prices, verify deployments, and monitor liquidation risk with a disciplined testing and security workflow.

The project is designed as a serious engineering portfolio piece: compact enough to audit, but broad enough to show real DeFi integration judgment.

## Highlights

- Aave V3 supply, withdraw, borrow, and repay flows
- Post-borrow health-factor validation
- Native ETH wrapping through WETH-compatible tokens
- Two-step ownership transfer for multisig-friendly administration
- Emergency pause controls for risk-increasing operations
- Safe ERC20 handling for standard and no-return tokens
- Aave account data lens for collateral, debt, LTV, liquidation threshold, and health factor
- Aave oracle lens for prices, price sources, and portfolio value estimates
- Network deployment configs for Ethereum, Arbitrum, Optimism, Polygon, and Base
- Deployment verification script for constructor/config checks
- Health-factor monitoring script and liquidation-risk runbook
- Unit, fork, security, fuzz, and invariant tests
- GitHub Actions CI with Foundry, coverage summary, Slither, and Aderyn

## Architecture

```text
src/
  AaveSupplyManager.sol        Owner-controlled Aave treasury adapter
  AavePositionLens.sol         Read-only account risk helper
  AaveOracleLens.sol           Read-only oracle and value helper
  interfaces/                  Minimal protocol and token interfaces
  libraries/                   Aave address book and SafeERC20 helper

script/
  DeployAaveSupplyManager.s.sol
  VerifyDeployment.s.sol
  CheckAaveHealth.s.sol

config/deployments/
  ethereum.json
  arbitrum.json
  optimism.json
  polygon.json
  base.json

test/
  fork/                        Optional real Aave V3 fork tests
  invariant/                   Stateful accounting invariants
  security/                    Access-control and emergency-control tests
  mocks/                       Local protocol/token/oracle mocks

docs/
  DEPLOYMENT.md
  MONITORING.md
  RISK_ASSUMPTIONS.md
  SECURITY_REVIEW.md
```

## Core Contract

`AaveSupplyManager` owns the Aave position. Supplied collateral and debt are accounted to the manager contract, while the owner, ideally a multisig, controls treasury actions.

Supported flows:

- `supplyToken`
- `supplyNative`
- `withdrawToken`
- `borrowToken`
- `borrowVariableToken`
- `repayToken`
- `rescueToken`
- `pause` / `unpause`
- two-step `transferOwnership` / `acceptOwnership`

Borrowing checks the manager health factor after the Aave borrow call and reverts if it is below the caller-provided minimum. Because the transaction reverts, the debt and transfer are rolled back.

## Security Posture

This repository includes production-oriented hardening, but it is not a substitute for an external audit.

Implemented controls:

- owner-only mutating operations
- two-step ownership handoff
- pause gate for supply, borrow, and repay
- emergency withdraw/rescue path while paused
- explicit zero-address and zero-amount validation
- SafeERC20 optional-return handling
- post-borrow health-factor guard
- deployment verification script
- documented assumptions and residual risks

Security documentation:

- [Internal security review](docs/SECURITY_REVIEW.md)
- [Risk assumptions](docs/RISK_ASSUMPTIONS.md)
- [Monitoring strategy](docs/MONITORING.md)

## Testing

Run the full local suite:

```shell
forge test
```

Run formatting and build checks:

```shell
forge fmt --check
forge build --sizes
```

The test suite includes:

- deterministic unit tests
- security regression tests
- fuzz tests for withdraw, borrow, and repay boundaries
- invariant tests for supply/debt accounting
- optional Ethereum mainnet fork tests against real Aave V3 contracts

Current configured fuzz and invariant settings are in [foundry.toml](foundry.toml).

## Fork Tests

Set `MAINNET_RPC_URL` to execute real Aave V3 fork scenarios:

```shell
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/<key> forge test --match-path test/fork/*
```

Without `MAINNET_RPC_URL`, fork tests use the local skip path so the default suite remains clone-and-run friendly.

## CI And Static Analysis

GitHub Actions workflows:

- `.github/workflows/test.yml`: Foundry format, build, test, and coverage summary
- `.github/workflows/security.yml`: Slither static analysis with SARIF upload and Aderyn high-severity gate

Slither and Aderyn fail the security workflow on high-severity findings. These tools improve review discipline, but they do not replace an external audit.

## Deployment

Copy the environment template:

```shell
cp .env.example .env
```

Example deployment variables:

```shell
DEPLOYMENT_CONFIG=config/deployments/ethereum.json
OWNER=0xYourMultisig
```

Deploy:

```shell
forge script script/DeployAaveSupplyManager.s.sol:DeployAaveSupplyManager \
  --rpc-url <RPC_URL> \
  --private-key <PRIVATE_KEY> \
  --broadcast \
  --verify
```

Verify the deployed manager:

```shell
DEPLOYMENT_CONFIG=config/deployments/ethereum.json \
MANAGER=0xDeployedManager \
OWNER=0xYourMultisig \
forge script script/VerifyDeployment.s.sol:VerifyDeployment \
  --rpc-url <RPC_URL>
```

Deployment guide: [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)

## Monitoring

Read live Aave account risk for a deployed manager:

```shell
DEPLOYMENT_CONFIG=config/deployments/ethereum.json \
MANAGER=0xDeployedManager \
forge script script/CheckAaveHealth.s.sol:CheckAaveHealth \
  --rpc-url <RPC_URL>
```

The monitoring script prints account metrics and classifies the position as:

- `NO_DEBT`
- `HEALTHY`
- `WARNING`
- `CRITICAL`

Monitoring runbook: [docs/MONITORING.md](docs/MONITORING.md)

## Production Readiness

This repo is production-inspired, not production-certified. Before managing meaningful funds:

- refresh addresses from the official Aave address book
- deploy with a multisig owner
- run target-network fork tests
- run Slither and Aderyn in CI
- complete external audit or independent review
- implement live monitoring and alerting
- perform a small capped deployment first

---

### Connect

* GitHub: [https://github.com/dappteacher](https://github.com/dappteacher)
* LinkedIn: [https://linkedin.com/in/dappteacher](https://linkedin.com/in/dappteacher)

---
