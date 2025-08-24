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