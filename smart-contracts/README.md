# SavETH – Smart Contracts

This directory contains the core smart contract logic for the SavETH dApp.

## 📁 Structure

- `src/` – Contract source code
- `test/` – Foundry tests
- `script/` – Deployment scripts
- `lib/` – External libraries
- `broadcast/` – Deployment artifacts (gitignored)
- `out/` – Build output (gitignored)

## 🔨 Tools Used

- [Foundry](https://github.com/foundry-rs/foundry) – Solidity dev toolkit
- Solidity `^0.8.24`

## 📃 Contract
`src/SavingsVault.sol`
- Allows users to create multiple savings goals
- ETH is locked per goal until target is reached
- Funds can only be withdrawn after completion
- Public usernames supported (optional)

## 🚀 Deployment

Deployment script:  
`script/DeploySavingsVault.s.sol`

To deploy to Optimism Sepolia:
```bash
forge script script/DeploySavingsVault.s.sol:DeploySavingsVault \
  --rpc-url $OPTIMISM_SEPOLIA_RPC \
  --keystore $KEYSTORE \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_KEY -vvvv
```

## ✅ Testing

Run all tests:
```bash
forge test
```

Run tests with gas reports:
```bash
forge test --gas-report
```