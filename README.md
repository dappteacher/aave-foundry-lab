# Aave V3 Supply Manager

A small pure Foundry project that demonstrates Solidity integration patterns around Aave V3. The core contract is an owner-controlled treasury adapter that can supply ERC20 assets or native ETH, represented as WETH, into an Aave-compatible pool, withdraw supplied liquidity, borrow against collateral with a health-factor guard, and repay debt. Companion lens contracts read Aave account data and oracle prices for collateral, debt, borrow capacity, liquidation threshold, LTV, health factor, asset prices, and portfolio value estimates.

This is intentionally compact enough to review quickly, but it still shows practical DeFi engineering habits: minimal protocol interfaces, custom errors, events, two-step ownership controls, pause controls, deterministic tests, mocks, and a deployment script driven by environment variables.

## What It Shows

- Aave V3 `supply` and `withdraw` integration through a focused pool interface.
- Aave V3 `borrow` and `repay` flow with post-borrow health-factor validation.
- Native ETH handling by wrapping to WETH before supplying to Aave.
- Owner-only treasury operations with two-step ownership transfer, explicit validation, and custom errors.
- Emergency pause controls that block risk-increasing actions while still allowing owner-controlled withdrawal/rescue operations.
- Safe ERC20 handling for standard tokens and tokens that do not return boolean values.
- Unit tests that run locally without RPC access or forked mainnet state.
- Optional Ethereum mainnet fork test against the real Aave V3 Pool.
- Reusable address-book library for supported Aave V3 markets.
- Position lens for Aave V3 account and health-factor data.
- Oracle lens for Aave asset prices, price sources, and base-currency value estimates.
- Internal security review notes and regression tests for access-control and risk boundaries.
- Slippage, price, and risk assumptions documented with fuzz and invariant coverage.
- Real network deployment configs and health-factor monitoring runbook.
- A deployment script suitable for real Aave V3 deployments once addresses are configured.

## Project Layout

```text
src/
  AaveSupplyManager.sol        Main treasury adapter
  AavePositionLens.sol         Read-only account risk helper
  AaveOracleLens.sol           Read-only Aave oracle price helper
  interfaces/                  Minimal ERC20, WETH, and Aave V3 interfaces
  libraries/                   Network-specific Aave V3 addresses
test/
  AaveSupplyManager.t.sol      Unit tests
  fork/                        Optional mainnet fork integration test
  invariant/                   Stateful invariant tests for core flows
  mocks/                       Local pool, ERC20, and WETH mocks
  security/                    Security regression tests
script/
  DeployAaveSupplyManager.s.sol
  CheckAaveHealth.s.sol        Health-factor monitoring helper
docs/
  DEPLOYMENT.md                Per-network deployment config guide
  MONITORING.md                Health factor and liquidation-risk runbook
  RISK_ASSUMPTIONS.md          Slippage, price, and risk assumptions
  SECURITY_REVIEW.md           Internal review, residual risks, production checklist
```

## Usage

Install Foundry first if you do not already have it:

```shell
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Fork Integration Test

Set an Ethereum mainnet RPC endpoint to run the real Aave V3 integration test:

```shell
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/<key> forge test --match-path test/fork/*
```

Without `MAINNET_RPC_URL`, the fork test logs a skip message and exits early so the default suite remains clone-and-run friendly.

### Format

```shell
forge fmt
```

### Deploy

Set the target Aave V3 pool and wrapped native token for your network:

```shell
cp .env.example .env
```

Example values:

```shell
USE_ADDRESS_BOOK=true
DEPLOYMENT_CONFIG=config/deployments/ethereum.json
AAVE_POOL=0x...
WRAPPED_NATIVE_TOKEN=0x...
OWNER=0x... # recommended: multisig address
```

By default, the deploy script reads `DEPLOYMENT_CONFIG` when provided. If no config file is set, it reads supported market addresses from `AaveV3Addresses` based on `block.chainid`. Set `USE_ADDRESS_BOOK=false` to provide `AAVE_POOL` and `WRAPPED_NATIVE_TOKEN` manually.

Then run:

```shell
forge script script/DeployAaveSupplyManager.s.sol:DeployAaveSupplyManager \
  --rpc-url <RPC_URL> \
  --private-key <PRIVATE_KEY> \
  --broadcast \
  --verify
```

## Notes

- This project uses local mocks for repeatable tests. For a production deployment, use the official Aave address book for the network you deploy to.
- The security review in `docs/SECURITY_REVIEW.md` is an internal review, not an external audit.
- Deployment config guidance is in `docs/DEPLOYMENT.md`; monitoring guidance is in `docs/MONITORING.md`.
- Slippage, price, and risk assumptions are documented in `docs/RISK_ASSUMPTIONS.md`.
- `OWNER` should be a multisig for serious deployments. Ownership transfer is two-step: the current owner proposes `pendingOwner`, then the pending owner accepts.
- `pause` blocks supply, borrow, and repay. Withdraw and rescue remain available so the owner can reduce exposure during an incident.
- `AaveSupplyManager` supplies assets on behalf of itself, so the contract owns the resulting Aave position.
- Borrowing also happens on behalf of the manager. The manager checks the resulting health factor before transferring borrowed tokens to the chosen recipient.
- `AaveOracleLens` accepts an `assetUnit` parameter for value estimates, such as `1e18` for WETH or `1e6` for USDC, so token decimal assumptions stay explicit.
- `rescueToken` is only for idle tokens accidentally left in the manager, not for assets already supplied into Aave.

---

# Author

Yaghoub Adelzadeh
Senior Blockchain Engineer

GitHub
[https://github.com/dappteacher](https://github.com/dappteacher)
