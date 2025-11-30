# 🚀 SolAce Quick Testing Guide

## 📋 Object IDs dari Publish

```bash
export PKG=0x65c1ce78c397a5ba47527ad2d67344773507b5803a4fe4626e32e3dfdf6e9dcb
export GOLD_CAP=0x03cea19cafb0a89b1dd21aae06b5d97fc5e78b8ed0256f0c36893ea93ad8e894
export USDC_CAP=0x6c0854d8d735c9a67d8e99514d9d1d6324b7ca5f3c9a2bc53d22d99fc18c0937
export ORACLE=0x9b9de6b7e20f77031894c7f796cd7ac61e0faf27d089f83ee726f7b6ed0266c5
export TREASURY=0xcb834024b86ae3b3b542eeaf98ecc319b8a572a05aa354671708fbd05ee9da2c
```

## 🧪 Testing Flow

### 1️⃣ Mint USDC (1000 USDC)

```bash
sui client call \
  --function mint_usdc \
  --module mock_usdc \
  --package $PKG \
  --args $USDC_CAP 1000000000 \
  --gas-budget 10000000
```

**Simpan USDC Coin ID dari output!**
```bash
export USDC_COIN=0x...  # Dari Created Objects
```

---

### 2️⃣ Create Wallet

```bash
sui client call \
  --function create_wallet \
  --module auto_swap \
  --package $PKG \
  --gas-budget 10000000
```

**Simpan Wallet ID dari output!**
```bash
export WALLET=0x...  # Dari Created Objects (SolAceWallet)
```

---

### 3️⃣ Deposit USDC → Auto Mint aceGOLD

**Scenario:** User deposit 100 USDC
- Harga emas: 100 USDC/gram
- Expected: Dapat 1.0 aceGOLD

```bash
sui client call \
  --function deposit_usdc \
  --module auto_swap \
  --package $PKG \
  --args $WALLET $TREASURY $USDC_COIN $GOLD_CAP $ORACLE \
  --gas-budget 10000000
```

**✅ Result:**
- User wallet: 1.0 aceGOLD (1_000_000_000 units)
- Treasury: 100 USDC reserve

---

### 4️⃣ Merchant Create Payment Request

**Scenario:** Kafe minta pembayaran 5 USDC

```bash
sui client call \
  --function create_payment_request \
  --module auto_swap \
  --package $PKG \
  --args 5000000 \
  --gas-budget 10000000
```

**Simpan Payment Request ID!**
```bash
export REQUEST=0x...  # Dari Created Objects (PaymentRequest)
```

---

### 5️⃣ User Pay QR → Auto Burn aceGOLD

**Scenario:** User bayar kafe 5 USDC
- System burn: 0.05 aceGOLD
- Merchant terima: 5 USDC dari Treasury

```bash
sui client call \
  --function pay_qr \
  --module auto_swap \
  --package $PKG \
  --args $WALLET $TREASURY $REQUEST $GOLD_CAP $ORACLE \
  --gas-budget 10000000
```

**✅ Result:**
- User remaining: 0.95 aceGOLD (~95 USDC value)
- Merchant received: 5 USDC
- Payment Request: `paid = true`

---

## 📊 Oracle Testing (Optional)

### Update Harga Emas

Simulasi kenaikan harga emas dari 100 → 110 USDC/gram:

```bash
sui client call \
  --function update_price \
  --module mock_oracle \
  --package $PKG \
  --args $ORACLE 110000000 \
  --gas-budget 10000000
```

**Impact:**
- User dengan 0.95 aceGOLD sekarang punya nilai ~104.5 USDC
- Profit dari kenaikan harga emas! 📈

---

## 🎯 Full Test Scenario

```bash
# Setup
export PKG=0x65c1ce78c397a5ba47527ad2d67344773507b5803a4fe4626e32e3dfdf6e9dcb
export GOLD_CAP=0x03cea19cafb0a89b1dd21aae06b5d97fc5e78b8ed0256f0c36893ea93ad8e894
export USDC_CAP=0x6c0854d8d735c9a67d8e99514d9d1d6324b7ca5f3c9a2bc53d22d99fc18c0937
export ORACLE=0x9b9de6b7e20f77031894c7f796cd7ac61e0faf27d089f83ee726f7b6ed0266c5
export TREASURY=0xcb834024b86ae3b3b542eeaf98ecc319b8a572a05aa354671708fbd05ee9da2c

# 1. Mint USDC
sui client call --function mint_usdc --module mock_usdc --package $PKG --args $USDC_CAP 1000000000 --gas-budget 10000000

# Set USDC_COIN dari output
export USDC_COIN=0x...

# 2. Create Wallet
sui client call --function create_wallet --module auto_swap --package $PKG --gas-budget 10000000

# Set WALLET dari output
export WALLET=0x...

# 3. Deposit
sui client call --function deposit_usdc --module auto_swap --package $PKG --args $WALLET $TREASURY $USDC_COIN $GOLD_CAP $ORACLE --gas-budget 10000000

# 4. Create Payment Request
sui client call --function create_payment_request --module auto_swap --package $PKG --args 5000000 --gas-budget 10000000

# Set REQUEST dari output
export REQUEST=0x...

# 5. Pay
sui client call --function pay_qr --module auto_swap --package $PKG --args $WALLET $TREASURY $REQUEST $GOLD_CAP $ORACLE --gas-budget 10000000
```

---

## 🔍 Expected Results

| Step | User aceGOLD | Treasury USDC | Merchant USDC |
|------|--------------|---------------|---------------|
| Initial | 0 | 0 | 0 |
| After Deposit | 1.0 | 100 | 0 |
| After Payment | 0.95 | 95 | 5 |

---

## 🎉 Success Indicators

✅ Deposit: User gold_balance = 1_000_000_000 (1.0 aceGOLD)
✅ Payment: Merchant received 5_000000 USDC
✅ Remaining: User gold_balance = 950_000_000 (0.95 aceGOLD)
✅ Request: `paid = true`

**Save in Gold, Pay in USDC! ✨**
