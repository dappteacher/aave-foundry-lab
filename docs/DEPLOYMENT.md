# Deployment Configuration

Date: 2026-05-24

## Network Configs

Deployment configs live in `config/deployments/`:

- `ethereum.json`
- `arbitrum.json`
- `optimism.json`
- `polygon.json`
- `base.json`

Each config contains:

- `chainId`
- RPC environment variable name
- explorer URL
- Aave Pool Addresses Provider
- Aave Pool
- Aave Oracle
- wrapped native token
- USDC address used by monitoring/fork examples
- health-factor thresholds for monitoring

The contract deployment script reads `DEPLOYMENT_CONFIG` when provided:

```shell
DEPLOYMENT_CONFIG=config/deployments/ethereum.json \
OWNER=0xYourMultisig \
forge script script/DeployAaveSupplyManager.s.sol:DeployAaveSupplyManager \
  --rpc-url $MAINNET_RPC_URL \
  --broadcast \
  --verify
```

If `DEPLOYMENT_CONFIG` is not set, the script can still use the Solidity address book for supported chains through `USE_ADDRESS_BOOK=true`.

## Pre-Deployment Checklist

- Confirm the config file matches the target chain.
- Confirm `OWNER` is a multisig address.
- Confirm the deployer has native gas funds.
- Run `forge test`.
- Run the target fork tests if an RPC endpoint is available.
- Dry-run the script without `--broadcast`.
- Save the deployed manager address.
- Run the deployment verification script.
- Run the health check script after deployment.

## Post-Deployment Verification

After deployment, verify that the deployed manager matches the expected config:

```shell
DEPLOYMENT_CONFIG=config/deployments/ethereum.json \
MANAGER=0xDeployedManager \
OWNER=0xYourMultisig \
EXPECTED_PAUSED=false \
forge script script/VerifyDeployment.s.sol:VerifyDeployment \
  --rpc-url $MAINNET_RPC_URL
```

The script checks:

- manager Pool equals the config Pool
- manager wrapped native token equals the config asset
- manager owner equals `OWNER`
- manager pause state equals `EXPECTED_PAUSED`
- manager has no pending ownership transfer

Run this immediately after deployment and after any ownership transfer.

## Address Sources

The deployment configs are based on the BGD/Aave address book and Aave deployment references. Because protocol deployments can evolve, refresh these configs against the official address book before managing meaningful funds.
