# 🌾 Blockchain Farm Inventory Ledger

A comprehensive Clarity smart contract for tracking crop inventory, storage conditions, and sales records on the Stacks blockchain with oracle verification.

## 📋 Overview

This smart contract enables farmers to maintain transparent, immutable records of their agricultural operations including:

- 🌱 **Crop Registration**: Record harvest details with quality grades
- 🏪 **Storage Tracking**: Monitor storage conditions and facility details  
- 💰 **Sales Management**: Track sales transactions and delivery status
- ✅ **Oracle Verification**: Third-party verification of records
- 📊 **Inventory Management**: Real-time inventory tracking per farmer

## 🚀 Features

### For Farmers
- Register crops with harvest details
- Track storage conditions (temperature, humidity)
- Create and manage sales records
- Monitor available inventory in real-time

### For Oracles
- Verify crop authenticity and quality
- Validate storage conditions
- Confirm sales transactions

### For Contract Owner
- Authorize/remove oracle validators
- Maintain system integrity

## 📖 Usage Instructions

### 1. Register as a Farmer
```clarity
(contract-call? .blockchain-farm-inventory-ledger register-farmer)
```

### 2. Add Crop Record
```clarity
(contract-call? .blockchain-farm-inventory-ledger add-crop 
  "Tomatoes" 
  u1000 
  u1640995200 
  "Grade-A" 
  "Farm-Location-123")
```

### 3. Add Storage Record
```clarity
(contract-call? .blockchain-farm-inventory-ledger add-storage-record 
  u1 
  "Cold-Storage-Facility-A" 
  4 
  u85 
  "Excellent")
```

### 4. Create Sale
```clarity
(contract-call? .blockchain-farm-inventory-ledger create-sale 
  u1 
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 
  u500 
  u10)
```

### 5. Oracle Verification
```clarity
(contract-call? .blockchain-farm-inventory-ledger verify-crop u1)
(contract-call? .blockchain-farm-inventory-ledger verify-storage u1)
(contract-call? .blockchain-farm-inventory-ledger verify-sale u1)
```

## 🔍 Read-Only Functions

### Query Crop Information
```clarity
(contract-call? .blockchain-farm-inventory-ledger get-crop u1)
```

### Check Farmer Inventory
```clarity
(contract-call? .blockchain-farm-inventory-ledger get-farmer-inventory 
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 
  "Tomatoes")
```

### Get Storage Records
```clarity
(contract-call? .blockchain-farm-inventory-ledger get-storage-record u1)
```

### View Sales Data
```clarity
(contract-call? .blockchain-farm-inventory-ledger get-sale-record u1)
```

## 🛡️ Security Features

- **Access Control**: Role-based permissions for farmers, oracles, and contract owner
- **Inventory Validation**: Prevents overselling with real-time inventory checks
- **Oracle Verification**: Third-party validation ensures data integrity
- **Immutable Records**: All transactions permanently recorded on blockchain

## 📊 Data Structures

### Crop Record
- Farmer address
- Crop type and quantity
- Harvest date and location
- Quality grade
- Oracle verification status

### Storage Record
- Associated crop ID
- Storage facility details
- Environmental conditions
- Verification status

### Sales Record
- Crop and quantity details
- Buyer/seller information
- Pricing and delivery status
- Transaction verification

## 🔧 Error Codes

- `u100`: Owner only operation
- `u101`: Record not found
- `u102`: Unauthorized access
- `u103`: Invalid amount
- `u104`: Insufficient inventory
- `u105`: Record already exists
- `u106`: Invalid oracle

## 🌟 Benefits

- **Transparency**: Complete supply chain visibility
- **Traceability**: Track products from farm to consumer
- **Quality Assurance**: Oracle-verified quality standards
- **Fraud Prevention**: Immutable record keeping
- **Market Access**: Verified products command premium prices

## 🚀 Getting Started

1. Deploy the contract to Stacks blockchain
2. Register as a farmer using `register-farmer`
3. Add oracle validators (contract owner only)
4. Start recording crop, storage, and sales data
5. Utilize oracle verification for enhanced credibility

---

*Built with ❤️ for sustainable agriculture and transparent food systems*
```

**Git Commit Message:**
```
feat: implement blockchain farm inventory ledger with oracle verification
```

**GitHub Pull Request Title:**
```
🌾 Add Blockchain Farm Inventory Ledger Smart Contract
```

**GitHub Pull Request Description:**
```
## Summary
Added a comprehensive farm inventory management smart contract that enables transparent tracking of agricultural operations on the Stacks blockchain.

## Features Added
- **Crop Registration**: Farmers can register crops with harvest details and quality grades
- **Storage Tracking**: Monitor storage conditions including temperature and humidity
- **Sales Management**: Create and track sales transactions with delivery status
- **Oracle Verification**: Third-party verification system for data integrity
- **Inventory Management**: Real-time tracking of available vs total inventory
- **Access Control**: Role-based permissions for farmers, oracles, and contract owner

## Technical Implementation
- 150+ lines of Clarity code with comprehensive error handling
- Multiple data maps for crops, storage, and sales records
- Read-only functions for querying all record types
- Automated inventory updates on sales transactions
- Oracle authorization system for verification

## Use Cases
- Supply chain transparency for agricultural products
- Quality assurance through oracle verification
-
