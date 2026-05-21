# Aave V3 Supply Manager

A small pure Foundry project that demonstrates Solidity integration patterns around Aave V3. The core contract is an owner-controlled treasury adapter that can supply ERC20 assets or native ETH, represented as WETH, into an Aave-compatible pool and withdraw supplied liquidity back to a chosen recipient.

This is intentionally compact enough to review quickly, but it still shows practical DeFi engineering habits: minimal protocol interfaces, custom errors, events, ownership controls, deterministic tests, mocks, and a deployment script driven by environment variables.

## What It Shows

- Aave V3 `supply` and `withdraw` integration through a focused pool interface.
- Native ETH handling by wrapping to WETH before supplying to Aave.
- Owner-only treasury operations with explicit validation and custom errors.
- Unit tests that run locally without RPC access or forked mainnet state.
- A deployment script suitable for real Aave V3 deployments once addresses are configured.

## Project Layout

```text
src/
  AaveSupplyManager.sol        Main treasury adapter
  interfaces/                  Minimal ERC20, WETH, and Aave V3 interfaces
test/
  AaveSupplyManager.t.sol      Unit tests
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
AAVE_POOL=0x...
WRAPPED_NATIVE_TOKEN=0x...
OWNER=0x...
```

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
- `rescueToken` is only for idle tokens accidentally left in the manager, not for assets already supplied into Aave.

---

# Author

Yaghoub Adelzadeh
Blockchain Engineer

GitHub
[https://github.com/dappteacher](https://github.com/dappteacher)