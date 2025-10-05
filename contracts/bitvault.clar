;; Title: BitVault Protocol
;; Summary: Decentralized collateralized debt position (CDP) platform enabling Bitcoin holders 
;;          to mint synthetic assets while maintaining exposure to their BTC holdings
;; Description: BitVault is a comprehensive DeFi protocol built on Stacks that allows users to 
;;              leverage their Bitcoin as collateral to create synthetic assets representing various 
;;              real-world and crypto assets. The protocol features a robust liquidation mechanism, 
;;              oracle-based price feeds, governance system, liquidity pools, flash loans, limit orders, 
;;              and an insurance fund to protect against systemic risks. Users can maintain their 
;;              Bitcoin exposure while accessing liquidity through over-collateralized positions.

;; ERROR CODES
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u1001))
(define-constant ERR-INVALID-AMOUNT (err u1002))
(define-constant ERR-VAULT-NOT-FOUND (err u1003))
(define-constant ERR-PRICE-EXPIRED (err u1004))
(define-constant ERR-VAULT-UNDERCOLLATERALIZED (err u1005))
(define-constant ERR-LIQUIDATION-FAILED (err u1006))
(define-constant ERR-POOL-INSUFFICIENT-LIQUIDITY (err u1007))
(define-constant ERR-ASSET-NOT-SUPPORTED (err u1008))
(define-constant ERR-COOLDOWN-PERIOD (err u1009))
(define-constant ERR-MAX-SUPPLY-REACHED (err u1010))
(define-constant ERR-ORACLE-DATA-UNAVAILABLE (err u1011))
(define-constant ERR-GOVERNANCE-REJECTION (err u1012))
(define-constant ERR-INSURANCE-CLAIM-REJECTED (err u1013))
(define-constant ERR-REFERRAL-NOT-FOUND (err u1014))
(define-constant ERR-TRADING-PAIR-NOT-FOUND (err u1015))
(define-constant ERR-FLASH-LOAN-FAILED (err u1016))
(define-constant ERR-VAULT-LOCKED (err u1017))
(define-constant ERR-INSUFFICIENT-BALANCE (err u1018))
(define-constant ERR-SWAP-SLIPPAGE-EXCEEDED (err u1019))
(define-constant ERR-LIMIT-ORDER-INVALID (err u1020))
(define-constant ERR-NFT-COLLATERAL-INVALID (err u1021))
(define-constant ERR-YIELD-FARM-NOT-FOUND (err u1022))

;; SYSTEM PARAMETERS
(define-constant MIN-COLLATERALIZATION-RATIO u150)    ;; 150% minimum collateral ratio
(define-constant LIQUIDATION-THRESHOLD u120)          ;; 120% liquidation threshold
(define-constant LIQUIDATION-PENALTY u10)             ;; 10% liquidation penalty
(define-constant PROTOCOL-FEE u5)                     ;; 0.5% protocol fee
(define-constant ORACLE-PRICE-EXPIRY u3600)           ;; 1 hour price expiry
(define-constant COOLDOWN-PERIOD u86400)              ;; 24 hours cooldown
(define-constant PRECISION-FACTOR u1000000)           ;; 6 decimal precision

;; DATA MAPS - CORE PROTOCOL

;; Supported synthetic asset types
(define-map supported-assets
  { asset-id: uint }
  {
    name: (string-ascii 24),
    is-active: bool,
    max-supply: uint,
    current-supply: uint,
    collateral-ratio: uint
  }
)

;; User vaults for collateralized positions
(define-map vaults
  { owner: principal, asset-id: uint }
  {
    collateral-amount: uint,
    debt-amount: uint,
    last-update: uint,
    liquidation-in-progress: bool
  }
)

;; Oracle price data storage
(define-map asset-prices
  { asset-id: uint }
  {
    price: uint,
    last-update: uint,
    source: principal
  }
)

;; Liquidity pool reserves
(define-map liquidity-pools
  { asset-id: uint }
  {
    stx-balance: uint,
    synthetic-balance: uint,
    total-shares: uint
  }
)

;; LP token holder balances
(define-map lp-balances
  { asset-id: uint, owner: principal }
  { shares: uint }
)

;; Synthetic asset user balances
(define-map synthetic-asset-balances
  { asset-id: uint, owner: principal }
  { balance: uint }
)

;; DATA MAPS - EXTENDED FEATURES

;; Staking positions
(define-map staked-balances
  { owner: principal }
  {
    amount: uint,
    lock-until: uint,
    accumulated-yield: uint,
    last-claim: uint
  }
)

;; Governance proposal registry
(define-map governance-proposals
  { proposal-id: uint }
  {
    proposer: principal,
    description: (string-utf8 256),
    function-call: (buff 128),
    votes-for: uint,
    votes-against: uint,
    start-block: uint,
    end-block: uint,
    executed: bool,
    execution-block: uint
  }
)

;; Proposal voting records
(define-map proposal-votes
  { proposal-id: uint, voter: principal }
  { 
    vote: bool,
    weight: uint
  }
)

;; Asset utilization tracking
(define-map asset-utilization
  { asset-id: uint }
  {
    total-collateral: uint,
    total-borrowed: uint,
    base-rate: uint,
    utilization-multiplier: uint,
    last-rate-update: uint
  }
)

;; Time-locked asset positions
(define-map asset-locks
  { owner: principal, asset-id: uint }
  {
    locked-amount: uint,
    unlock-height: uint
  }
)

;; Authorized oracle registry
(define-map authorized-oracles
  { address: principal }
  { 
    is-active: bool,
    asset-types: (list 10 uint)
  }
)

;; Insurance claim records
(define-map insurance-claims 
  { claim-id: uint }
  {
    claimant: principal,
    asset-id: uint,
    amount: uint,
    status: (string-ascii 10),
    timestamp: uint
  }
)

;; Trading pair configurations
(define-map trading-pairs
  { pair-id: uint }
  {
    asset-a-id: uint,
    asset-b-id: uint,
    reserve-a: uint,
    reserve-b: uint,
    fee: uint,
    is-active: bool
  }
)

;; Flash loan tracking
(define-map flash-loans
  { loan-id: uint }
  {
    borrower: principal,
    asset-id: uint,
    amount: uint,
    fee: uint,
    is-active: bool,
    timestamp: uint
  }
)

;; Limit order book
(define-map limit-orders
  { order-id: uint }
  {
    owner: principal,
    pair-id: uint,
    is-buy: bool,
    amount: uint,
    price: uint,
    filled-amount: uint,
    status: (string-ascii 10),
    expiration: uint
  }
)

;; DATA VARIABLES - PROTOCOL STATE
(define-data-var protocol-paused bool false)
(define-data-var governance-address principal tx-sender)
(define-data-var treasury-address principal tx-sender)
(define-data-var total-protocol-fees uint u0)
(define-data-var last-yield-distribution uint u0)
(define-data-var yield-fee-percentage uint u20)
(define-data-var total-staked-tokens uint u0)
(define-data-var proposal-counter uint u0)
(define-data-var insurance-fund-balance uint u0)
(define-data-var insurance-premium-rate uint u2)
(define-data-var insurance-coverage-ratio uint u80)
(define-data-var claim-counter uint u0)
(define-data-var pair-counter uint u0)
(define-data-var flash-loan-counter uint u0)
(define-data-var flash-loan-fee-rate uint u9)
(define-data-var order-counter uint u0)

;; GOVERNANCE FUNCTIONS

;; Update governance address
(define-public (set-governance-address (new-address principal))
  (begin
    (asserts! (is-eq tx-sender (var-get governance-address)) ERR-NOT-AUTHORIZED)
    (ok (var-set governance-address new-address))
  )
)

;; Update treasury address
(define-public (set-treasury-address (new-address principal))
  (begin
    (asserts! (is-eq tx-sender (var-get governance-address)) ERR-NOT-AUTHORIZED)
    (ok (var-set treasury-address new-address))
  )
)

;; Emergency pause protocol
(define-public (pause-protocol)
  (begin
    (asserts! (is-eq tx-sender (var-get governance-address)) ERR-NOT-AUTHORIZED)
    (ok (var-set protocol-paused true))
  )
)

;; Resume protocol operations
(define-public (resume-protocol)
  (begin
    (asserts! (is-eq tx-sender (var-get governance-address)) ERR-NOT-AUTHORIZED)
    (ok (var-set protocol-paused false))
  )
)

;; ASSET MANAGEMENT FUNCTIONS

;; Add new supported synthetic asset
(define-public (add-supported-asset 
  (asset-id uint) 
  (name (string-ascii 24)) 
  (max-supply uint) 
  (collateral-ratio uint))
  (begin
    (asserts! (is-eq tx-sender (var-get governance-address)) ERR-NOT-AUTHORIZED)
    (asserts! (>= collateral-ratio MIN-COLLATERALIZATION-RATIO) ERR-INVALID-AMOUNT)
    (ok (map-set supported-assets 
      { asset-id: asset-id } 
      { 
        name: name, 
        is-active: true, 
        max-supply: max-supply, 
        current-supply: u0, 
        collateral-ratio: collateral-ratio 
      }
    ))
  )
)

;; Update asset active status
(define-public (update-asset-status (asset-id uint) (is-active bool))
  (begin
    (asserts! (is-eq tx-sender (var-get governance-address)) ERR-NOT-AUTHORIZED)
    (match (map-get? supported-assets { asset-id: asset-id })
      asset-data (ok (map-set supported-assets 
        { asset-id: asset-id } 
        (merge asset-data { is-active: is-active })
      ))
      ERR-ASSET-NOT-SUPPORTED
    )
  )
)

;; Update asset collateral ratio
(define-public (update-collateral-ratio (asset-id uint) (new-ratio uint))
  (begin
    (asserts! (is-eq tx-sender (var-get governance-address)) ERR-NOT-AUTHORIZED)
    (asserts! (>= new-ratio MIN-COLLATERALIZATION-RATIO) ERR-INVALID-AMOUNT)
    (match (map-get? supported-assets { asset-id: asset-id })
      asset-data (ok (map-set supported-assets 
        { asset-id: asset-id } 
        (merge asset-data { collateral-ratio: new-ratio })
      ))
      ERR-ASSET-NOT-SUPPORTED
    )
  )
)

;; ORACLE MANAGEMENT FUNCTIONS

;; Configure oracle authorization
(define-public (set-oracle 
  (oracle-address principal) 
  (is-active bool) 
  (asset-types (list 10 uint)))
  (begin
    (asserts! (is-eq tx-sender (var-get governance-address)) ERR-NOT-AUTHORIZED)
    (ok (map-set authorized-oracles
      { address: oracle-address }
      { 
        is-active: is-active,
        asset-types: asset-types
      }
    ))
  )
)

;; Update asset price (oracle only)
(define-public (update-price (asset-id uint) (price uint))
  (begin
    (match (map-get? authorized-oracles { address: tx-sender })
      oracle-data
      (begin
        (asserts! (get is-active oracle-data) ERR-NOT-AUTHORIZED)
        (asserts! (> price u0) ERR-INVALID-AMOUNT)
        (asserts! (is-some (index-of (get asset-types oracle-data) asset-id)) ERR-NOT-AUTHORIZED)
        (ok (map-set asset-prices
          { asset-id: asset-id }
          {
            price: price,
            last-update: stacks-block-height,
            source: tx-sender
          }
        ))
      )
      ERR-NOT-AUTHORIZED
    )
  )
)

;; Query current asset price
(define-public (query-price (asset-id uint))
  (begin
    (match (map-get? asset-prices { asset-id: asset-id })
      price-data
      (begin
        (asserts! (< (- stacks-block-height (get last-update price-data)) ORACLE-PRICE-EXPIRY) 
          ERR-PRICE-EXPIRED)
        (ok (get price price-data))
      )
      ERR-ORACLE-DATA-UNAVAILABLE
    )
  )
)

;; INSURANCE FUND FUNCTIONS

;; Contribute to insurance fund
(define-public (contribute-to-insurance-fund (amount uint))
  (begin
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (var-set insurance-fund-balance (+ (var-get insurance-fund-balance) amount))
    (ok (var-get insurance-fund-balance))
  )
)

;; File insurance claim
(define-public (file-insurance-claim (asset-id uint) (amount uint))
  (begin
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (let ((claim-id (var-get claim-counter)))
      (var-set claim-counter (+ claim-id u1))
      (map-set insurance-claims 
        { claim-id: claim-id }
        {
          claimant: tx-sender,
          asset-id: asset-id,
          amount: amount,
          status: "pending",
          timestamp: stacks-block-height
        }
      )
      (ok claim-id)
    )
  )
)

;; Review and process insurance claim (governance only)
(define-public (review-insurance-claim (claim-id uint) (approve bool))
  (begin
    (asserts! (is-eq tx-sender (var-get governance-address)) ERR-NOT-AUTHORIZED)
    (match (map-get? insurance-claims { claim-id: claim-id })
      claim-data
      (begin
        (if approve
          (begin
            (let 
              (
                (payout-amount (/ (* (get amount claim-data) (var-get insurance-coverage-ratio)) u100))
              )
              (asserts! (<= payout-amount (var-get insurance-fund-balance)) 
                ERR-INSUFFICIENT-COLLATERAL)
              (var-set insurance-fund-balance (- (var-get insurance-fund-balance) payout-amount))
              (map-set insurance-claims
                { claim-id: claim-id }
                (merge claim-data { status: "approved" })
              )
              (ok payout-amount)
            )
          )
          (begin
            (map-set insurance-claims
              { claim-id: claim-id }
              (merge claim-data { status: "rejected" })
            )
            (ok u0)
          )
        )
      )
      ERR-INSURANCE-CLAIM-REJECTED
    )
  )
)

;; Get insurance fund information
(define-public (get-insurance-fund-info)
  (ok {
    balance: (var-get insurance-fund-balance),
    premium-rate: (var-get insurance-premium-rate),
    coverage-ratio: (var-get insurance-coverage-ratio)
  })
)

;; TRADING PAIR FUNCTIONS

;; Create new trading pair
(define-public (create-trading-pair (asset-a-id uint) (asset-b-id uint) (fee uint))
  (begin
    (asserts! (is-eq tx-sender (var-get governance-address)) ERR-NOT-AUTHORIZED)
    (asserts! (is-asset-supported asset-a-id) ERR-ASSET-NOT-SUPPORTED)
    (asserts! (is-asset-supported asset-b-id) ERR-ASSET-NOT-SUPPORTED)
    (asserts! (not (is-eq asset-a-id asset-b-id)) ERR-INVALID-AMOUNT)
    (asserts! (<= fee u1000) ERR-INVALID-AMOUNT)
    (let ((pair-id (var-get pair-counter)))
      (map-set trading-pairs
        { pair-id: pair-id }
        {
          asset-a-id: asset-a-id,
          asset-b-id: asset-b-id,
          reserve-a: u0,
          reserve-b: u0,
          fee: fee,
          is-active: true
        }
      )
      (var-set pair-counter (+ pair-id u1))
      (ok pair-id)
    )
  )
)

;; FLASH LOAN FUNCTIONS

;; Execute flash loan
(define-public (flash-loan 
  (asset-id uint) 
  (amount uint) 
  (callback-contract principal) 
  (callback-function (string-ascii 128)))
  (begin
    (asserts! (not (var-get protocol-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (is-asset-supported asset-id) ERR-ASSET-NOT-SUPPORTED)
    (let
      (
        (loan-id (var-get flash-loan-counter))
        (loan-fee (/ (* amount (var-get flash-loan-fee-rate)) u10000))
      )
      (match (map-get? liquidity-pools { asset-id: asset-id })
        pool-data
        (begin
          (asserts! (>= (get synthetic-balance pool-data) amount) ERR-POOL-INSUFFICIENT-LIQUIDITY)
          (map-set flash-loans
            { loan-id: loan-id }
            {
              borrower: tx-sender,
              asset-id: asset-id,
              amount: amount,
              fee: loan-fee,
              is-active: true,
              timestamp: stacks-block-height
            }
          )
          (var-set flash-loan-counter (+ loan-id u1))
          (map-set flash-loans
            { loan-id: loan-id }
            {
              borrower: tx-sender,
              asset-id: asset-id,
              amount: amount,
              fee: loan-fee,
              is-active: false,
              timestamp: stacks-block-height
            }
          )
          (var-set total-protocol-fees (+ (var-get total-protocol-fees) loan-fee))
          (ok loan-id)
        )
        ERR-POOL-INSUFFICIENT-LIQUIDITY
      )
    )
  )
)

;; LIMIT ORDER FUNCTIONS

;; Create limit order
(define-public (create-limit-order 
  (pair-id uint) 
  (is-buy bool) 
  (amount uint) 
  (price uint) 
  (expiration uint))
  (begin
    (asserts! (not (var-get protocol-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (> price u0) ERR-INVALID-AMOUNT)
    (asserts! (> expiration stacks-block-height) ERR-INVALID-AMOUNT)
    (match (map-get? trading-pairs { pair-id: pair-id })
      pair-data
      (begin
        (asserts! (get is-active pair-data) ERR-TRADING-PAIR-NOT-FOUND)
        (let
          (
            (order-id (var-get order-counter))
            (required-balance (* amount price))
          )
          (map-set limit-orders
            { order-id: order-id }
            {
              owner: tx-sender,
              pair-id: pair-id,
              is-buy: is-buy,
              amount: amount,
              price: price,
              filled-amount: u0,
              status: "open",
              expiration: expiration
            }
          )
          (var-set order-counter (+ order-id u1))
          (ok order-id)
        )
      )
      ERR-TRADING-PAIR-NOT-FOUND
    )
  )
)

;; Cancel limit order
(define-public (cancel-limit-order (order-id uint))
  (begin
    (match (map-get? limit-orders { order-id: order-id })
      order-data
      (begin
        (asserts! (or 
          (is-eq tx-sender (get owner order-data))
          (>= stacks-block-height (get expiration order-data))
        ) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status order-data) "open") ERR-LIMIT-ORDER-INVALID)
        (map-set limit-orders
          { order-id: order-id }
          (merge order-data { status: "cancelled" })
        )
        (ok true)
      )
      ERR-LIMIT-ORDER-INVALID
    )
  )
)

;; Execute limit order
(define-public (execute-limit-order (order-id uint))
  (begin
    (asserts! (not (var-get protocol-paused)) ERR-NOT-AUTHORIZED)
    (match (map-get? limit-orders { order-id: order-id })
      order-data
      (begin
        (asserts! (is-eq (get status order-data) "open") ERR-LIMIT-ORDER-INVALID)
        (asserts! (< stacks-block-height (get expiration order-data)) ERR-LIMIT-ORDER-INVALID)
        (match (map-get? trading-pairs { pair-id: (get pair-id order-data) })
          pair-data
          (begin
            (asserts! (get is-active pair-data) ERR-TRADING-PAIR-NOT-FOUND)
            (let
              (
                (current-price (/ (* (get reserve-b pair-data) PRECISION-FACTOR) 
                  (get reserve-a pair-data)))
              )
              (asserts! (if (get is-buy order-data)
                (<= current-price (get price order-data))
                (>= current-price (get price order-data))
              ) ERR-LIMIT-ORDER-INVALID)
              (map-set limit-orders
                { order-id: order-id }
                (merge order-data { 
                  status: "filled",
                  filled-amount: (get amount order-data)
                })
              )
              (ok true)
            )
          )
          ERR-TRADING-PAIR-NOT-FOUND
        )
      )
      ERR-LIMIT-ORDER-INVALID
    )
  )
)

;; PRIVATE HELPER FUNCTIONS

;; Check if address is authorized oracle
(define-private (is-oracle (address principal))
  (is-eq address (var-get governance-address))
)

;; Get asset price with validation
(define-private (get-price (asset-id uint))
  (match (map-get? asset-prices { asset-id: asset-id })
    price-data (begin
      (asserts! (< (- stacks-block-height (get last-update price-data)) ORACLE-PRICE-EXPIRY) 
        ERR-PRICE-EXPIRED)
      (ok (get price price-data))
    )
    ERR-ORACLE-DATA-UNAVAILABLE
  )
)

;; Get BTC price
(define-private (get-btc-price)
  (get-price u0)
)

;; Check if asset is supported
(define-private (is-asset-supported (asset-id uint))
  (match (map-get? supported-assets { asset-id: asset-id })
    asset-data (get is-active asset-data)
    false
  )
)