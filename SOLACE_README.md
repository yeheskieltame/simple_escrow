# SolAce - Save in Gold, Pay in USDC

Smart contract untuk dompet digital berbasis blockchain SUI yang menggabungkan keamanan investasi emas dengan kemudahan uang tunai.

## 📁 Struktur Project

```
sources/
├── mock_usdc.move      # Mock stablecoin USDC (6 decimals)
├── acegold.move        # Token aceGOLD (9 decimals) - synthetic gold
├── mock_oracle.move    # Mock Oracle untuk harga emas
└── auto_swap.move      # Core logic: Auto-swap USDC ↔ aceGOLD
```

## 🎯 Konsep Inti

**Masalah:**
- Uang tunai tergerus inflasi
- Emas susah dipakai untuk transaksi harian
- Trading manual ribet (buy/sell manual)

**Solusi:**
- **Deposit USDC** → Auto mint aceGOLD (simpan sebagai emas)
- **Bayar QR** → Auto burn aceGOLD → kirim USDC (cairkan emas)
- User tidak perlu trading manual, semuanya otomatis!

## 🔧 Cara Kerja

### 1. Setup Awal

```move
// User buat wallet pertama kali
sui client call --function create_wallet \
  --module auto_swap \
  --package $PACKAGE_ID
```

### 2. Deposit USDC (Save in Gold)

**User Flow:**
1. User deposit 100 USDC
2. Oracle: 1 gram emas = 100 USDC
3. System auto mint 1.0 aceGOLD ke wallet user
4. USDC masuk ke Protocol Treasury

**Code:**
```move
deposit_usdc(wallet, treasury, usdc_coin, gold_cap, oracle)
```

### 3. Bayar QR (Pay in USDC)

**User Flow:**
1. Merchant buat QR: 5 USDC
2. User scan QR dan klik bayar
3. System hitung: butuh burn 0.05 aceGOLD
4. System burn aceGOLD user
5. System kirim 5 USDC dari treasury ke merchant

**Code:**
```move
pay_qr(wallet, treasury, payment_request, gold_cap, oracle)
```

## 📊 Contoh Matematika

**Deposit:**
```
Input:  100 USDC (100_000000 - 6 decimals)
Price:  1 gram = 100 USDC
Output: 1.0 aceGOLD (1_000000000 - 9 decimals)
Formula: (usdc * 1e9) / price
```

**Payment:**
```
Input:  0.05 aceGOLD (50_000000 - 9 decimals)
Price:  1 gram = 100 USDC
Output: 5 USDC (5_000000 - 6 decimals)
Formula: (gold * price) / 1e9
```

## 🔐 Security Features

1. **Authorization Check**: Hanya owner wallet yang bisa deposit/bayar
2. **Balance Check**: Cek saldo gold sebelum payment
3. **Treasury Reserve**: USDC disimpan di shared treasury
4. **Mint/Burn Control**: aceGOLD hanya bisa mint/burn via protocol

## 🚀 Deployment Guide

```bash
# 1. Build project
sui move build

# 2. Deploy
sui client publish --gas-budget 100000000

# 3. Save object IDs:
# - PACKAGE_ID
# - TREASURY_ID (ProtocolTreasury)
# - GOLD_CAP_ID (TreasuryCap<ACEGOLD>)
# - USDC_CAP_ID (TreasuryCap<MOCK_USDC>)
# - ORACLE_ID (GoldPriceOracle)

# 4. Mint USDC untuk testing
sui client call \
  --function mint_usdc \
  --module mock_usdc \
  --package $PACKAGE_ID \
  --args $USDC_CAP_ID 1000000000 \
  --gas-budget 10000000

# 5. Create wallet
sui client call \
  --function create_wallet \
  --module auto_swap \
  --package $PACKAGE_ID \
  --gas-budget 10000000

# 6. Deposit USDC
sui client call \
  --function deposit_usdc \
  --module auto_swap \
  --package $PACKAGE_ID \
  --args $WALLET_ID $TREASURY_ID $USDC_COIN_ID $GOLD_CAP_ID $ORACLE_ID \
  --gas-budget 10000000
```

## 🏗️ Architecture

```
┌─────────────┐
│    User     │
└──────┬──────┘
       │
       ↓
┌─────────────────────────────────────┐
│      SolAceWallet (User)            │
│  • gold_balance: Balance<ACEGOLD>   │
└──────┬──────────────────────────────┘
       │
       ↓
┌─────────────────────────────────────┐
│     Auto Swap Logic                 │
│  • deposit_usdc()  → mint aceGOLD   │
│  • pay_qr()        → burn aceGOLD   │
└──────┬──────────────────────────────┘
       │
       ↓
┌─────────────────────────────────────┐
│   ProtocolTreasury (Shared)         │
│  • usdc_reserve: Balance<USDC>      │
└─────────────────────────────────────┘
```

## 📝 Next Steps (Production)

1. **Oracle Integration**: Ganti mock_oracle dengan Pyth Network / Switchboard
2. **Price Feed**: Real-time XAU/USD feed
3. **Frontend**: Build UI dengan Next.js + ZKLogin
4. **QR Scanner**: Integrasi QR code generator/scanner
5. **Fee System**: Tambah protocol fee untuk sustainability

## 🎓 Filosofi

> "Uang yang didiamkan harusnya tumbuh (Emas),
> tapi uang yang mau dipakai harusnya mudah (USDC)."

**Safe like Gold. Fast like Cash.**
