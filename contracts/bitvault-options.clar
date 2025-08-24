;; Title: BitVault Options - Decentralized Bitcoin Options Trading
;; Network: Stacks (Bitcoin Layer-2)
;;
;; Summary:
;; BitVault Options is a sophisticated decentralized options trading protocol
;; built natively on Stacks, enabling trustless Bitcoin-backed derivatives.
;; Users can write, trade, and exercise both call and put options with
;; full collateralization and automated settlement mechanisms.
;;
;; Description:
;; This protocol revolutionizes Bitcoin options trading by providing:
;; - Fully collateralized options with automatic settlement
;; - Multi-token support through whitelisted SIP-010 compliant assets
;; - Real-time price oracle integration for accurate option pricing
;; - Decentralized governance with configurable protocol parameters
;; - Advanced position management and risk assessment tools
;; - Gas-optimized execution for seamless user experience

;; TRAIT DEFINITIONS

;; Standard SIP-010 fungible token trait for multi-token support
(define-trait sip-010-trait (
  (transfer
    (uint principal principal (optional (buff 34)))
    (response bool uint)
  )
  (get-balance
    (principal)
    (response uint uint)
  )
  (get-total-supply
    ()
    (response uint uint)
  )
  (get-decimals
    ()
    (response uint uint)
  )
  (get-token-uri
    ()
    (response (optional (string-utf8 256)) uint)
  )
  (get-name
    ()
    (response (string-ascii 32) uint)
  )
  (get-symbol
    ()
    (response (string-ascii 32) uint)
  )
))

;; ERROR CONSTANTS

;; Core authorization and balance errors
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INSUFFICIENT-BALANCE (err u1001))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u1006))

;; Option-specific errors
(define-constant ERR-INVALID-EXPIRY (err u1002))
(define-constant ERR-INVALID-STRIKE-PRICE (err u1003))
(define-constant ERR-OPTION-NOT-FOUND (err u1004))
(define-constant ERR-OPTION-EXPIRED (err u1005))
(define-constant ERR-ALREADY-EXERCISED (err u1007))
(define-constant ERR-INVALID-PREMIUM (err u1008))

;; Validation and security errors
(define-constant ERR-INVALID-TOKEN (err u1009))
(define-constant ERR-INVALID-SYMBOL (err u1010))
(define-constant ERR-INVALID-TIMESTAMP (err u1011))
(define-constant ERR-INVALID-ADDRESS (err u1012))
(define-constant ERR-ZERO-ADDRESS (err u1013))
(define-constant ERR-EMPTY-SYMBOL (err u1014))

;; UTILITY FUNCTIONS

;; Returns the minimum of two unsigned integers
(define-private (get-min
    (a uint)
    (b uint)
  )
  (if (< a b)
    a
    b
  )
)

;; DATA STRUCTURES

;; Core options registry - tracks all option contracts
(define-map options
  uint
  {
    writer: principal, ;; Option writer (seller)
    holder: (optional principal), ;; Option holder (buyer)
    collateral-amount: uint, ;; Locked collateral
    strike-price: uint, ;; Exercise price
    premium: uint, ;; Option premium paid
    expiry: uint, ;; Expiration block height
    is-exercised: bool, ;; Exercise status
    option-type: (string-ascii 4), ;; "CALL" or "PUT"
    state: (string-ascii 9), ;; "ACTIVE" or "EXERCISED"
  }
)

;; User position tracking for portfolio management
(define-map user-positions
  principal
  {
    written-options: (list 10 uint), ;; Options written by user
    held-options: (list 10 uint), ;; Options owned by user
    total-collateral-locked: uint, ;; Total collateral committed
  }
)

;; Whitelist for approved trading tokens
(define-map approved-tokens
  principal
  bool
)

;; Price oracle data feeds
(define-map price-feeds
  (string-ascii 10)
  {
    price: uint, ;; Current price in micro-units
    timestamp: uint, ;; Last update timestamp
    source: principal, ;; Oracle data provider
  }
)

;; Approved trading pairs and symbols
(define-map allowed-symbols
  (string-ascii 10)
  bool
)

;; STATE VARIABLES

;; Unique identifier counter for new options
(define-data-var next-option-id uint u1)

;; Protocol governance parameters
(define-data-var contract-owner principal tx-sender)
(define-data-var protocol-fee-rate uint u100) ;; 1% = 100 basis points

;; CORE OPTION FUNCTIONS

;; Write a new option contract
;; Creates a new options contract with specified parameters
(define-public (write-option
    (token <sip-010-trait>)
    (collateral-amount uint)
    (strike-price uint)
    (premium uint)
    (expiry uint)
    (option-type (string-ascii 4))
  )
  (let (
      (option-id (var-get next-option-id))
      (current-time stacks-block-height)
      (token-principal (contract-of token))
    )
    ;; Comprehensive parameter validation
    (asserts! (is-approved-token token-principal) ERR-INVALID-TOKEN)
    (asserts! (> expiry current-time) ERR-INVALID-EXPIRY)
    (asserts! (> strike-price u0) ERR-INVALID-STRIKE-PRICE)
    (asserts! (> premium u0) ERR-INVALID-PREMIUM)
    (asserts!
      (check-collateral-requirement collateral-amount strike-price option-type)
      ERR-INSUFFICIENT-COLLATERAL
    )

    ;; Lock collateral in contract escrow
    (try! (contract-call? token transfer collateral-amount tx-sender
      (as-contract tx-sender) none
    ))

    ;; Create and store option contract
    (map-set options option-id {
      writer: tx-sender,
      holder: none,
      collateral-amount: collateral-amount,
      strike-price: strike-price,
      premium: premium,
      expiry: expiry,
      is-exercised: false,
      option-type: option-type,
      state: "ACTIVE",
    })

    ;; Update writer's position tracking
    (let ((current-position (default-to {
        written-options: (list),
        held-options: (list),
        total-collateral-locked: u0,
      }
        (map-get? user-positions tx-sender)
      )))
      (map-set user-positions tx-sender
        (merge current-position {
          written-options: (unwrap-panic (as-max-len? (append (get written-options current-position) option-id)
            u10
          )),
          total-collateral-locked: (+ (get total-collateral-locked current-position) collateral-amount),
        })
      )
    )

    ;; Increment option counter and return new option ID
    (var-set next-option-id (+ option-id u1))
    (ok option-id)
  )
)

;; Purchase an existing option
;; Allows users to buy options by paying the premium
(define-public (buy-option
    (token <sip-010-trait>)
    (option-id uint)
  )
  (let (
      (option (unwrap! (map-get? options option-id) ERR-OPTION-NOT-FOUND))
      (premium (get premium option))
      (token-principal (contract-of token))
    )
    ;; Validate purchase eligibility
    (asserts! (is-approved-token token-principal) ERR-INVALID-TOKEN)
    (asserts! (is-none (get holder option)) ERR-ALREADY-EXERCISED)
    (asserts! (< stacks-block-height (get expiry option)) ERR-OPTION-EXPIRED)

    ;; Transfer premium from buyer to writer
    (try! (contract-call? token transfer premium tx-sender (get writer option) none))

    ;; Assign option ownership to buyer
    (map-set options option-id (merge option { holder: (some tx-sender) }))

    ;; Update buyer's position tracking
    (let ((current-position (default-to {
        written-options: (list),
        held-options: (list),
        total-collateral-locked: u0,
      }
        (map-get? user-positions tx-sender)
      )))
      (map-set user-positions tx-sender
        (merge current-position { held-options: (unwrap-panic (as-max-len? (append (get held-options current-position) option-id) u10)) })
      )
    )

    (ok true)
  )
)

;; Exercise an owned option
;; Allows option holders to exercise their rights
(define-public (exercise-option
    (token <sip-010-trait>)
    (option-id uint)
  )
  (let (
      (option (unwrap! (map-get? options option-id) ERR-OPTION-NOT-FOUND))
      (current-price (get-current-price))
      (token-principal (contract-of token))
    )
    ;; Validate exercise authorization
    (asserts! (is-approved-token token-principal) ERR-INVALID-TOKEN)
    (asserts! (is-eq (some tx-sender) (get holder option)) ERR-NOT-AUTHORIZED)
    (asserts! (not (get is-exercised option)) ERR-ALREADY-EXERCISED)
    (asserts! (< stacks-block-height (get expiry option)) ERR-OPTION-EXPIRED)

    ;; Execute appropriate exercise logic
    (if (is-eq (get option-type option) "CALL")
      (exercise-call token option current-price)
      (exercise-put token option current-price)
    )
  )
)

;; PRIVATE HELPER FUNCTIONS

;; Validate collateral requirements based on option type
(define-private (check-collateral-requirement
    (amount uint)
    (strike uint)
    (option-type (string-ascii 4))
  )
  (if (is-eq option-type "CALL")
    (>= amount strike)
    (>= amount (/ (* strike u100000000) (get-current-price)))
  )
)

;; Execute call option exercise
(define-private (exercise-call
    (token <sip-010-trait>)
    (option {
      writer: principal,
      holder: (optional principal),
      collateral-amount: uint,
      strike-price: uint,
      premium: uint,
      expiry: uint,
      is-exercised: bool,
      option-type: (string-ascii 4),
      state: (string-ascii 9),
    })
    (current-price uint)
  )
  (let (
      (profit (- current-price (get strike-price option)))
      (payout (get-min profit (get collateral-amount option)))
    )
    ;; Transfer profit to option holder
    (try! (as-contract (contract-call? token transfer payout tx-sender
      (unwrap! (get holder option) ERR-NOT-AUTHORIZED) none
    )))

    ;; Return remaining collateral to writer
    (try! (as-contract (contract-call? token transfer (- (get collateral-amount option) payout)
      tx-sender (get writer option) none
    )))

    ;; Mark option as exercised
    (map-set options (get-option-id option)
      (merge option {
        is-exercised: true,
        state: "EXERCISED",
      })
    )

    (ok true)
  )
)