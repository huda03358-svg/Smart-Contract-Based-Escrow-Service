# 🔒 Smart Contract-Based Escrow Service

A decentralized escrow service built on the Stacks blockchain using Clarity smart contracts. This service enables secure peer-to-peer transactions with built-in dispute resolution.

## ✨ Features

- 💰 **Secure Fund Holding**: STX tokens are held safely in the contract until release conditions are met
- 👥 **Three-Party System**: Buyer, seller, and arbiter roles for trusted transactions
- ⏰ **Deadline Management**: Time-bound escrows with automatic refund capabilities
- ⚖️ **Dispute Resolution**: Built-in arbitration system for handling conflicts
- 🔍 **Transparent Tracking**: All escrow states are publicly verifiable on-chain

## 📋 Contract Overview

The escrow service manages secure transactions between buyers and sellers with the following workflow:

1. **Buyer** creates an escrow by depositing STX and specifying seller, arbiter, and deadline
2. **Seller** delivers goods/services as agreed
3. **Buyer** releases funds to seller upon satisfaction, or raises a dispute if issues arise
4. **Arbiter** resolves disputes by deciding fund distribution
5. **Automatic refunds** occur if deadlines pass without action

## 🚀 Usage

### Creating an Escrow

```clarity
(contract-call? .escrow-service create-escrow
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7  ;; seller address
  'SP1QK1AZ24R132C0D84EEQ8Y2JDHARDR58SMAYMMW  ;; arbiter address
  u1000000                                      ;; amount in micro-STX
  u1000                                         ;; deadline block height
)
```

### Releasing Funds to Seller

```clarity
(contract-call? .escrow-service release-funds u1)  ;; escrow-id
```

### Refunding Funds to Buyer

```clarity
(contract-call? .escrow-service refund-funds u1)  ;; escrow-id
```

### Raising a Dispute

```clarity
(contract-call? .escrow-service raise-dispute u1)  ;; escrow-id
```

### Resolving a Dispute (Arbiter Only)

```clarity
(contract-call? .escrow-service resolve-dispute
  u1      ;; escrow-id
  true    ;; true = release to seller, false = refund to buyer
)
```

### Extending the Deadline

```clarity
(contract-call? .escrow-service extend-deadline
  u1      ;; escrow-id
  u2000   ;; new deadline block height
)
```

## 📖 Read-Only Functions

### Get Escrow Details

```clarity
(contract-call? .escrow-service get-escrow u1)
```

### Get Dispute Information

```clarity
(contract-call? .escrow-service get-dispute u1)
```

### Check Escrow Status

```clarity
(contract-call? .escrow-service get-escrow-status u1)
```

### Check if Expired

```clarity
(contract-call? .escrow-service is-escrow-expired u1)
```

### Check Permissions

```clarity
(contract-call? .escrow-service can-release u1 'SP...)
(contract-call? .escrow-service can-refund u1 'SP...)
(contract-call? .escrow-service can-dispute u1 'SP...)
```

## 🔢 Escrow States

- `0` - **Pending**: Escrow is active and awaiting action
- `1` - **Released**: Funds have been released to the seller
- `2` - **Refunded**: Funds have been returned to the buyer
- `3` - **Disputed**: Escrow is under arbitration

## 🛡️ Security Features

- ✅ Only authorized parties can release or refund funds
- ✅ Time-based controls prevent premature or late actions
- ✅ Dispute mechanism protects both buyer and seller
- ✅ Funds are held securely in the contract context
- ✅ All state transitions are validated and atomic

## 🧪 Testing

To test the contract:

```bash
clarinet check
clarinet test
```

## 📦 Deployment

1. Ensure Clarinet is installed
2. Run `clarinet check` to verify the contract
3. Deploy using Clarinet or Hiro Platform

## 🤝 Roles & Permissions

### Buyer
- Create escrow
- Release funds to seller
- Raise disputes
- Refund after deadline passes
- Extend deadline (with seller agreement)

### Seller
- Receive funds upon release
- Raise disputes
- Refund before deadline (if agreed)
- Extend deadline (with buyer agreement)

### Arbiter
- Release or refund at any time
- Resolve disputes with final decision

## 📝 Error Codes

- `u100` - Owner-only operation
- `u101` - Escrow not found
- `u102` - Unauthorized action
- `u103` - Escrow already exists
- `u104` - Invalid amount
- `u105` - Invalid status for operation
- `u106` - Already released
- `u107` - Already refunded
- `u108` - Deadline not passed
- `u109` - Deadline passed

## 📄 License

MIT License

## 🌟 Contributing

Contributions are welcome! Please open an issue or submit a pull request.
