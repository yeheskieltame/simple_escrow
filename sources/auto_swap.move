module simple_escrow::auto_swap {
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::balance::{Self, Balance};
    use simple_escrow::acegold::ACEGOLD;
    use simple_escrow::mock_usdc::MOCK_USDC;
    use simple_escrow::mock_oracle::{Self, GoldPriceOracle};

    /// Error codes
    const E_INSUFFICIENT_PAYMENT: u64 = 0;
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_INSUFFICIENT_GOLD: u64 = 2;

    /// Protocol Treasury: Simpan USDC cadangan untuk liquidity.
    /// Shared object agar semua user bisa akses.
    public struct ProtocolTreasury has key {
        id: UID,
        /// USDC reserve dari semua deposit user.
        usdc_reserve: Balance<MOCK_USDC>,
    }

    /// SolAce Wallet: User's digital wallet.
    /// Menyimpan aceGOLD (emas) di belakang layar.
    public struct SolAceWallet has key {
        id: UID,
        /// Saldo emas user (invisible untuk user, auto-managed).
        gold_balance: Balance<ACEGOLD>,
        owner: address,
    }

    /// Payment Request: QR code untuk pembayaran.
    /// Merchant buat request, user scan dan bayar.
    public struct PaymentRequest has key {
        id: UID,
        /// Jumlah USDC yang diminta merchant.
        amount_usdc: u64,
        /// Address merchant yang akan terima pembayaran.
        merchant: address,
        /// Status: apakah sudah dibayar.
        paid: bool,
    }

    // ========== USER FUNCTIONS ==========

    /// User topup: Kirim USDC, otomatis jadi aceGOLD.
    /// "Save in Gold" - Protection dari inflasi.
    public entry fun deposit_usdc(
        wallet: &mut SolAceWallet,
        treasury: &mut ProtocolTreasury,
        usdc: Coin<MOCK_USDC>,
        gold_cap: &mut TreasuryCap<ACEGOLD>,
        oracle: &GoldPriceOracle,
        ctx: &mut TxContext,
    ) {
        assert!(wallet.owner == ctx.sender(), E_NOT_AUTHORIZED);

        let usdc_amount = usdc.value();

        // Hitung berapa aceGOLD yang didapat dari USDC ini.
        let gold_amount = mock_oracle::calculate_gold_from_usdc(oracle, usdc_amount);

        // Simpan USDC ke treasury sebagai reserve.
        balance::join(&mut treasury.usdc_reserve, usdc.into_balance());

        // Mint aceGOLD ke wallet user.
        let new_gold = simple_escrow::acegold::mint(gold_cap, gold_amount, ctx);
        balance::join(&mut wallet.gold_balance, new_gold.into_balance());
    }

    /// User bayar QR: Bakar aceGOLD, kirim USDC ke merchant.
    /// "Pay in USDC" - Auto-swap invisible untuk user.
    public entry fun pay_qr(
        wallet: &mut SolAceWallet,
        treasury: &mut ProtocolTreasury,
        request: &mut PaymentRequest,
        gold_cap: &mut TreasuryCap<ACEGOLD>,
        oracle: &GoldPriceOracle,
        ctx: &mut TxContext,
    ) {
        assert!(wallet.owner == ctx.sender(), E_NOT_AUTHORIZED);
        assert!(!request.paid, E_INSUFFICIENT_PAYMENT);

        let usdc_needed = request.amount_usdc;

        // Hitung berapa aceGOLD yang harus dibakar.
        let gold_to_burn = mock_oracle::calculate_usdc_from_gold(oracle, usdc_needed);

        // Cek saldo gold user cukup.
        assert!(wallet.gold_balance.value() >= gold_to_burn, E_INSUFFICIENT_GOLD);

        // Ambil aceGOLD dari wallet user.
        let gold_to_burn_balance = wallet.gold_balance.split(gold_to_burn);
        let gold_coin = coin::from_balance(gold_to_burn_balance, ctx);

        // Burn aceGOLD.
        simple_escrow::acegold::burn(gold_cap, gold_coin);

        // Ambil USDC dari treasury dan kirim ke merchant.
        let usdc_balance = treasury.usdc_reserve.split(usdc_needed);
        let usdc_payment = coin::from_balance(usdc_balance, ctx);
        transfer::public_transfer(usdc_payment, request.merchant);

        // Mark request sebagai paid.
        request.paid = true;
    }

    /// Cek saldo emas user (dalam aceGOLD).
    public fun check_gold_balance(wallet: &SolAceWallet): u64 {
        balance::value(&wallet.gold_balance)
    }

    /// Estimasi nilai USDC dari saldo emas user.
    public fun estimate_usdc_value(
        wallet: &SolAceWallet,
        oracle: &GoldPriceOracle,
    ): u64 {
        let gold_amount = balance::value(&wallet.gold_balance);
        mock_oracle::calculate_usdc_from_gold(oracle, gold_amount)
    }

    /// Cek reserve USDC di treasury.
    public fun check_treasury_reserve(treasury: &ProtocolTreasury): u64 {
        balance::value(&treasury.usdc_reserve)
    }

    // ========== MERCHANT FUNCTIONS ==========

    /// Merchant buat QR code payment request.
    public entry fun create_payment_request(
        amount_usdc: u64,
        ctx: &mut TxContext,
    ) {
        let request = PaymentRequest {
            id: object::new(ctx),
            amount_usdc,
            merchant: ctx.sender(),
            paid: false,
        };
        transfer::share_object(request);
    }

    // ========== SETUP FUNCTIONS ==========

    /// Init: Buat Protocol Treasury (saat deploy).
    fun init(ctx: &mut TxContext) {
        let treasury = ProtocolTreasury {
            id: object::new(ctx),
            usdc_reserve: balance::zero<MOCK_USDC>(),
        };
        transfer::share_object(treasury);
    }

    /// User buat wallet baru (first time setup).
    public entry fun create_wallet(ctx: &mut TxContext) {
        let wallet = SolAceWallet {
            id: object::new(ctx),
            gold_balance: balance::zero<ACEGOLD>(),
            owner: ctx.sender(),
        };
        transfer::transfer(wallet, ctx.sender());
    }
}
