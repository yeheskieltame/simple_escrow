#!/bin/bash

# ============================================
# SOLACE TESTING COMMANDS
# ============================================

# Export Object IDs dari hasil publish
export PKG=0x65c1ce78c397a5ba47527ad2d67344773507b5803a4fe4626e32e3dfdf6e9dcb
export GOLD_CAP=0x03cea19cafb0a89b1dd21aae06b5d97fc5e78b8ed0256f0c36893ea93ad8e894
export USDC_CAP=0x6c0854d8d735c9a67d8e99514d9d1d6324b7ca5f3c9a2bc53d22d99fc18c0937
export ORACLE=0x9b9de6b7e20f77031894c7f796cd7ac61e0faf27d089f83ee726f7b6ed0266c5
export TREASURY=0xcb834024b86ae3b3b542eeaf98ecc319b8a572a05aa354671708fbd05ee9da2c

echo "📦 Package ID: $PKG"
echo "🏦 Treasury: $TREASURY"
echo "📊 Oracle: $ORACLE"
echo "🪙 Gold Cap: $GOLD_CAP"
echo "💵 USDC Cap: $USDC_CAP"
echo ""

# ============================================
# STEP 1: Mint USDC untuk Testing (1000 USDC)
# ============================================
echo "💵 Step 1: Minting 1000 USDC..."
sui client call \
  --function mint_usdc \
  --module mock_usdc \
  --package $PKG \
  --args $USDC_CAP 1000000000 \
  --gas-budget 10000000

echo ""
echo "⚠️  SAVE USDC COIN ID from output above!"
echo "Export it: export USDC_COIN=0x..."
read -p "Press Enter after setting USDC_COIN..."

# ============================================
# STEP 2: Create Wallet User
# ============================================
echo ""
echo "👛 Step 2: Creating SolAce Wallet..."
sui client call \
  --function create_wallet \
  --module auto_swap \
  --package $PKG \
  --gas-budget 10000000

echo ""
echo "⚠️  SAVE WALLET ID from output above!"
echo "Export it: export WALLET=0x..."
read -p "Press Enter after setting WALLET..."

# ============================================
# STEP 3: Deposit USDC → Auto Mint aceGOLD
# ============================================
echo ""
echo "📥 Step 3: Depositing 100 USDC (will auto-convert to 1.0 aceGOLD)..."
echo "Using: USDC_COIN=$USDC_COIN"

sui client call \
  --function deposit_usdc \
  --module auto_swap \
  --package $PKG \
  --args $WALLET $TREASURY $USDC_COIN $GOLD_CAP $ORACLE \
  --gas-budget 10000000

echo ""
echo "✅ User now has ~1.0 aceGOLD in wallet!"
echo "   (100 USDC @ price 100 USDC/gram = 1 gram gold)"

# ============================================
# STEP 4: Merchant Create Payment Request (5 USDC)
# ============================================
echo ""
echo "🏪 Step 4: Merchant creating payment request for 5 USDC..."
sui client call \
  --function create_payment_request \
  --module auto_swap \
  --package $PKG \
  --args 5000000 \
  --gas-budget 10000000

echo ""
echo "⚠️  SAVE PAYMENT REQUEST ID from output above!"
echo "Export it: export REQUEST=0x..."
read -p "Press Enter after setting REQUEST..."

# ============================================
# STEP 5: User Pay QR → Auto Burn aceGOLD → Send USDC
# ============================================
echo ""
echo "💳 Step 5: User paying 5 USDC via QR (will burn 0.05 aceGOLD)..."
sui client call \
  --function pay_qr \
  --module auto_swap \
  --package $PKG \
  --args $WALLET $TREASURY $REQUEST $GOLD_CAP $ORACLE \
  --gas-budget 10000000

echo ""
echo "✅ Payment complete!"
echo "   - User burned: 0.05 aceGOLD"
echo "   - Merchant received: 5 USDC"
echo "   - User remaining: 0.95 aceGOLD (~95 USDC value)"

# ============================================
# BONUS: Update Oracle Price (Optional)
# ============================================
echo ""
echo "📊 BONUS: Update gold price (admin only)"
echo "Example: Set new price to 110 USDC/gram"
echo ""
echo "sui client call \\"
echo "  --function update_price \\"
echo "  --module mock_oracle \\"
echo "  --package $PKG \\"
echo "  --args $ORACLE 110000000 \\"
echo "  --gas-budget 10000000"

echo ""
echo "🎉 All testing steps completed!"
