# BitVault Options Protocol

![License](https://img.shields.io/badge/license-ISC-blue.svg)
![Stacks](https://img.shields.io/badge/Stacks-Bitcoin%20L2-orange.svg)
![Clarity](https://img.shields.io/badge/Clarity-v3-green.svg)

> **Decentralized Bitcoin Options Trading on Stacks**

BitVault Options is a sophisticated decentralized options trading protocol built natively on Stacks, enabling trustless Bitcoin-backed derivatives with full collateralization and automated settlement mechanisms.

## 🌟 Features

- **Fully Collateralized Options** - Complete collateral backing for all option positions
- **Multi-Token Support** - SIP-010 compliant asset integration with whitelisting
- **Real-Time Oracle Integration** - Accurate pricing through decentralized price feeds
- **Automated Settlement** - Trustless exercise and settlement mechanisms
- **Position Management** - Advanced portfolio tracking and risk assessment
- **Decentralized Governance** - Configurable protocol parameters
- **Gas Optimization** - Efficient execution for seamless user experience

## 🏗️ System Overview

### Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   User Layer    │    │  Oracle Layer   │    │ Governance Layer│
│                 │    │                 │    │                 │
│ • Option Writers│    │ • Price Feeds   │    │ • Admin Controls│
│ • Option Buyers │◄──►│ • BTC/USD       │◄──►│ • Fee Management│
│ • Exercisers    │    │ • STX/USD       │    │ • Token Whitelist│
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Core Protocol  │
                    │                 │
                    │ • Options Logic │
                    │ • Collateral    │
                    │ • Settlement    │
                    │ • Position Mgmt │
                    └─────────────────┘
```

### Core Components

1. **Options Engine** - Core logic for writing, trading, and exercising options
2. **Collateral Manager** - Handles asset locking and settlement
3. **Price Oracle** - External price feed integration
4. **Position Tracker** - User portfolio and risk management
5. **Governance Module** - Administrative controls and protocol parameters

## 🔧 Contract Architecture

### Data Structures

#### Option Contract

```clarity
{
  writer: principal,              ; Option seller
  holder: (optional principal),   ; Option buyer
  collateral-amount: uint,        ; Locked collateral
  strike-price: uint,            ; Exercise price
  premium: uint,                 ; Option cost
  expiry: uint,                  ; Expiration block
  is-exercised: bool,            ; Exercise status
  option-type: (string-ascii 4), ; "CALL" or "PUT"
  state: (string-ascii 9)        ; Contract state
}
```

#### User Position

```clarity
{
  written-options: (list 10 uint),    ; Written option IDs
  held-options: (list 10 uint),       ; Owned option IDs
  total-collateral-locked: uint       ; Total locked collateral
}
```

#### Price Feed

```clarity
{
  price: uint,        ; Current price in micro-units
  timestamp: uint,    ; Last update timestamp
  source: principal   ; Oracle provider
}
```

### Key Functions

#### Core Operations

- `write-option` - Create new option contracts with collateral
- `buy-option` - Purchase existing options by paying premium
- `exercise-option` - Exercise owned options for profit

#### Administrative Functions

- `set-protocol-fee-rate` - Configure protocol fees (max 10%)
- `update-price-feed` - Update oracle price data
- `set-approved-token` - Manage token whitelist
- `set-allowed-symbol` - Manage trading symbols

#### Read-Only Functions

- `get-option` - Retrieve option details
- `get-user-position` - Get user's complete position
- `get-protocol-fee-rate` - Current fee configuration

## 📊 Data Flow

### Option Writing Process

```
Writer → Validate Parameters → Lock Collateral → Create Option → Update Position
```

### Option Purchase Process

```
Buyer → Pay Premium → Transfer to Writer → Assign Ownership → Update Position
```

### Option Exercise Process

```
Holder → Validate Rights → Calculate Payout → Settle Funds → Update Status
```

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) v2.0+
- [Node.js](https://nodejs.org/) v18+
- [Stacks CLI](https://docs.stacks.co/stacks-cli) (optional)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/james-aemma/bitvault-options.git
   cd bitvault-options
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Run tests**

   ```bash
   npm test
   ```

4. **Check contracts**

   ```bash
   clarinet check
   ```

### Development Workflow

1. **Start development environment**

   ```bash
   clarinet console
   ```

2. **Run continuous testing**

   ```bash
   npm run test:watch
   ```

3. **Generate coverage reports**

   ```bash
   npm run test:report
   ```

## 🧪 Testing

The protocol includes comprehensive test coverage:

```bash
# Run all tests
npm test

# Run with coverage and gas cost analysis
npm run test:report

# Watch mode for development
npm run test:watch
```

Test files are located in `/tests/bitvault-options.test.ts`

## 📝 Usage Examples

### Writing a Call Option

```clarity
;; Write a BTC call option
(contract-call? .bitvault-options write-option
  .wrapped-btc          ; Collateral token
  u100000000           ; 1 BTC collateral (8 decimals)
  u5000000000          ; $50,000 strike price
  u500000000           ; $500 premium
  u144                 ; Expires in ~1 day (144 blocks)
  "CALL"               ; Option type
)
```

### Buying an Option

```clarity
;; Purchase option #1
(contract-call? .bitvault-options buy-option
  .wrapped-btc    ; Payment token
  u1              ; Option ID
)
```

### Exercising an Option

```clarity
;; Exercise owned option
(contract-call? .bitvault-options exercise-option
  .wrapped-btc    ; Settlement token
  u1              ; Option ID
)
```

## 🔒 Security Features

- **Full Collateralization** - All options are 100% backed by collateral
- **Input Validation** - Comprehensive parameter checking
- **Access Control** - Strict authorization for sensitive operations
- **Oracle Protection** - Validated price feed sources
- **Emergency Controls** - Administrative functions for protocol safety

## 🛠️ Configuration

### Protocol Parameters

- **Fee Rate**: Configurable up to 10% (1000 basis points)
- **Supported Tokens**: Whitelisted SIP-010 compliant assets
- **Price Feeds**: BTC-USD, STX-USD, and additional trading pairs
- **Position Limits**: Up to 10 options per user category

### Network Deployment

The protocol supports deployment on:

- **Testnet** - Development and testing
- **Mainnet** - Production deployment
- **Devnet** - Local development

Configuration files are located in `/settings/`

## 📚 API Reference

### Error Codes

| Code | Description | Constant |
|------|-------------|----------|
| 1000 | Not Authorized | `ERR-NOT-AUTHORIZED` |
| 1001 | Insufficient Balance | `ERR-INSUFFICIENT-BALANCE` |
| 1002 | Invalid Expiry | `ERR-INVALID-EXPIRY` |
| 1003 | Invalid Strike Price | `ERR-INVALID-STRIKE-PRICE` |
| 1004 | Option Not Found | `ERR-OPTION-NOT-FOUND` |
| 1005 | Option Expired | `ERR-OPTION-EXPIRED` |
| 1006 | Insufficient Collateral | `ERR-INSUFFICIENT-COLLATERAL` |
| 1007 | Already Exercised | `ERR-ALREADY-EXERCISED` |

### Constants

- **Maximum Fee Rate**: 1000 basis points (10%)
- **Maximum Position Size**: 10 options per category
- **Minimum Symbol Length**: 2 characters
- **Block Height Precision**: Stacks block height

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## 📄 License

This project is licensed under the ISC License - see the [LICENSE](LICENSE) file for details.
