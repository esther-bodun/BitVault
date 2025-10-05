# BitVault Protocol

## Overview

**BitVault Protocol** is a decentralized collateralized debt position (CDP) platform built on the **Stacks blockchain**, enabling Bitcoin holders to mint synthetic assets while maintaining exposure to their BTC holdings.
By locking BTC (via Stacks' Bitcoin settlement layer) as collateral, users can generate synthetic assets representing real-world and crypto assets, access liquidity, and participate in DeFi activities without selling their Bitcoin.

BitVault incorporates advanced features including:

* **Collateralized vaults & CDPs**
* **Synthetic asset minting & trading**
* **Oracle-driven price feeds**
* **Liquidation mechanisms**
* **Governance with proposal voting**
* **Insurance fund for systemic risk protection**
* **Liquidity pools & LP shares**
* **Limit orders & flash loans**

---

## System Architecture

At a high level, BitVault operates as a **layered DeFi protocol**:

1. **Vault Layer**

   * Users deposit collateral (BTC or supported assets).
   * Mint synthetic assets against over-collateralized positions.
   * Vaults are subject to collateral ratio checks and liquidation thresholds.

2. **Price Oracle Layer**

   * On-chain authorized oracles update asset prices.
   * Strict expiry mechanisms ensure stale data cannot be used.

3. **Risk & Liquidation Layer**

   * Liquidation triggered if vault collateralization < `LIQUIDATION-THRESHOLD`.
   * Liquidators receive incentives and penalties applied to undercollateralized vaults.

4. **Trading & Liquidity Layer**

   * Automated market maker–based liquidity pools.
   * Trading pairs configured with fee structures.
   * Limit orders supported for discrete price execution.
   * Flash loan support with fee enforcement.

5. **Governance Layer**

   * Token holders propose and vote on parameter changes.
   * Protocol upgrade control via governance address.
   * Treasury and insurance fund managed through governance.

6. **Insurance & Safety Layer**

   * Insurance fund accumulates premiums and contributions.
   * Governance reviews and approves claims.
   * Payouts capped by coverage ratio and fund balance.

---

## Contract Architecture

The BitVault contract follows a **modular mapping approach** with well-defined data structures:

* **Core Maps**

  * `supported-assets`: Registry of synthetic assets with collateral requirements.
  * `vaults`: Tracks user collateral, debt, and vault status.
  * `asset-prices`: Oracle-updated asset prices with expiry validation.
  * `liquidity-pools`: Reserves for AMM-based pools.
  * `synthetic-asset-balances`: User balances of minted synthetics.

* **Extended Maps**

  * `staked-balances`: Locked staking positions with yield accrual.
  * `governance-proposals` / `proposal-votes`: Governance decision-making.
  * `insurance-claims`: Claim lifecycle tracking (pending/approved/rejected).
  * `trading-pairs`: Order-book compatible AMM pairs.
  * `flash-loans`: Loan records for on-chain enforcement.
  * `limit-orders`: Limit order book with expiry and fill tracking.

* **State Variables**

  * `protocol-paused`: Emergency circuit breaker.
  * `governance-address`: Governance authority principal.
  * `treasury-address`: Protocol treasury recipient.
  * `insurance-fund-balance`: Accumulated reserve for claims.
  * `flash-loan-fee-rate`, `yield-fee-percentage`, etc.: Configurable economic parameters.

* **Governance Functions**

  * Control protocol pause/resume.
  * Manage assets, oracles, fees, and treasury.
  * Review insurance claims.

* **Oracle Functions**

  * `set-oracle`: Governance-authorized oracle registration.
  * `update-price`: Oracle-signed price submission.
  * `query-price`: Public price query with expiry validation.

* **User Functions**

  * Vault operations (mint, repay, withdraw – to be extended).
  * Liquidity provision, limit orders, and flash loan initiation.
  * Insurance fund contributions and claims.

---

## Data Flow (Simplified)

1. **Collateral Deposit**
   User deposits BTC → Vault entry created → Debt ceiling calculated based on `collateral-ratio`.

2. **Synthetic Minting**
   User mints synthetic assets → Debt recorded in vault → Synthetic tokens credited to user.

3. **Price Updates**
   Authorized oracle submits price → Stored in `asset-prices` with timestamp → Used for collateralization checks.

4. **Liquidation Trigger**
   Protocol checks vault collateralization → If below threshold, liquidation can be executed.

5. **Trading & Liquidity**
   Synthetic assets trade in liquidity pools or via limit orders → Pool reserves updated.

6. **Flash Loans**
   User requests flash loan → Loan issued if liquidity sufficient → Must be repaid within same transaction with fee.

7. **Governance & Insurance**
   Governance proposals voted on by stakeholders → System parameters updated.
   Claims filed and reviewed → Insurance fund pays valid claims.

---

## Key Parameters

* **Collateralization Ratio:** Minimum 150%
* **Liquidation Threshold:** 120%
* **Liquidation Penalty:** 10%
* **Protocol Fee:** 0.5%
* **Oracle Price Expiry:** 1 hour
* **Insurance Coverage Ratio:** 80%

---

## Security & Risk Considerations

* **Oracle Risk:** Multi-oracle registry reduces manipulation risk.
* **Liquidation Risk:** Penalties incentivize liquidators to act promptly.
* **Insurance Fund:** Provides partial coverage in case of systemic shortfalls.
* **Governance Control:** All critical parameters are adjustable only via governance.
* **Emergency Pause:** Circuit breaker allows halting protocol in critical scenarios.

---

## Future Extensions

* Integration with **sBTC** for direct Bitcoin collateral.
* Advanced liquidation auctions.
* DAO-controlled insurance underwriting.
* Cross-chain synthetic settlement via bridging.

---

## License

MIT License.
