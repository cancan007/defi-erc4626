# DeFi ERC4626 Vault (Hardhat + Slither + Echidna + Semgrep + Foundry Fuzz/Invariant)

This repo is a **minimal but standard** ERC-4626 vault implementation (OpenZeppelin v5) plus:
- Hardhat unit tests
- Slither config
- Semgrep rules
- Echidna harness + config
- Foundry fuzz + invariant test harness (recommended for invariants)

## Quick start
```bash
npm i
npm run build
npm test

# Static analysis
npm run slither
npm run semgrep

# Echidna (requires echidna installed locally)
npm run echidna

# Foundry fuzz/invariants (requires foundry installed locally)
npm run fuzz
```

## Notes
- The vault is ERC-4626 compliant via OpenZeppelin `ERC4626`.
- Reentrancy is guarded on state-changing ERC4626 entrypoints (deposit/mint/withdraw/redeem).
- Invariant tests focus on asset/share accounting consistency and "no free lunch" properties.
