# Aave V3 Supply Manager

A small pure Foundry project that demonstrates Solidity integration patterns around Aave V3. The core contract is an owner-controlled treasury adapter that can supply ERC20 assets or native ETH, represented as WETH, into an Aave-compatible pool, withdraw supplied liquidity, borrow against collateral with a health-factor guard, and repay debt. A companion lens contract reads Aave account data such as collateral, debt, borrow capacity, liquidation threshold, LTV, and health factor.

This is intentionally compact enough to review quickly, but it still shows practical DeFi engineering habits: minimal protocol interfaces, custom errors, events, ownership controls, deterministic tests, mocks, and a deployment script driven by environment variables.

## What It Shows

- Aave V3 `supply` and `withdraw` integration through a focused pool interface.
- Aave V3 `borrow` and `repay` flow with post-borrow health-factor validation.
- Native ETH handling by wrapping to WETH before supplying to Aave.
- Owner-only treasury operations with explicit validation and custom errors.
- Unit tests that run locally without RPC access or forked mainnet state.
- Optional Ethereum mainnet fork test against the real Aave V3 Pool.
- Reusable address-book library for supported Aave V3 markets.
- Position lens for Aave V3 account and health-factor data.
- A deployment script suitable for real Aave V3 deployments once addresses are configured.

## Project Layout

```text
src/
  AaveSupplyManager.sol        Main treasury adapter
  AavePositionLens.sol         Read-only account risk helper
  interfaces/                  Minimal ERC20, WETH, and Aave V3 interfaces
  libraries/                   Network-specific Aave V3 addresses
test/
  AaveSupplyManager.t.sol      Unit tests
  fork/                        Optional mainnet fork integration test
  mocks/                       Local pool, ERC20, and WETH mocks
script/
  DeployAaveSupplyManager.s.sol
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
AAVE_POOL=0x...
WRAPPED_NATIVE_TOKEN=0x...
OWNER=0x...
```

By default, the deploy script reads supported market addresses from `AaveV3Addresses` based on `block.chainid`. Set `USE_ADDRESS_BOOK=false` to provide `AAVE_POOL` and `WRAPPED_NATIVE_TOKEN` manually.

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
- `AaveSupplyManager` supplies assets on behalf of itself, so the contract owns the resulting Aave position.
- Borrowing also happens on behalf of the manager. The manager checks the resulting health factor before transferring borrowed tokens to the chosen recipient.
- `rescueToken` is only for idle tokens accidentally left in the manager, not for assets already supplied into Aave.

---

# Author

Yaghoub Adelzadeh
Senior Blockchain Engineer

GitHub
[https://github.com/dappteacher](https://github.com/dappteacher)
