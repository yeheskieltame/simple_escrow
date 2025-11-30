module simple_escrow::mock_oracle {
    /// Mock Oracle untuk harga emas (XAU/USD).
    /// Di production, pakai Pyth Network atau Switchboard.
    public struct GoldPriceOracle has key {
        id: UID,
        /// Harga 1 gram emas dalam USDC (scaled by 1e6 untuk USDC decimals).
        /// Example: 100_000000 = 100 USDC per gram.
        price_per_gram: u64,
        admin: address,
    }

    /// Init: buat Oracle dengan harga default.
    fun init(ctx: &mut TxContext) {
        let oracle = GoldPriceOracle {
            id: object::new(ctx),
            price_per_gram: 100_000000, // Default: 1 gram = 100 USDC
            admin: ctx.sender(),
        };
        transfer::share_object(oracle);
    }

    /// Update harga emas (admin only).
    public entry fun update_price(
        oracle: &mut GoldPriceOracle,
        new_price: u64,
        ctx: &TxContext,
    ) {
        assert!(ctx.sender() == oracle.admin, 0);
        oracle.price_per_gram = new_price;
    }

    /// Baca harga emas per gram (dalam USDC).
    public fun get_price(oracle: &GoldPriceOracle): u64 {
        oracle.price_per_gram
    }

    /// Hitung berapa aceGOLD yang didapat dari jumlah USDC tertentu.
    /// Formula: (usdc_amount * 1e9) / price_per_gram
    /// Example: 100 USDC (100_000000) -> 1 gram gold (1_000000000)
    public fun calculate_gold_from_usdc(oracle: &GoldPriceOracle, usdc_amount: u64): u64 {
        let price = oracle.price_per_gram;
        // aceGOLD (9 dec) = (USDC (6 dec) * 1e9) / price (6 dec)
        // Simplified: (usdc_amount * 1000)
        ((usdc_amount as u128) * 1_000_000_000 / (price as u128)) as u64
    }

    /// Hitung berapa USDC yang dibutuhkan untuk jumlah aceGOLD tertentu.
    /// Formula: (gold_amount * price_per_gram) / 1e9
    /// Example: 1 gram gold (1_000000000) -> 100 USDC (100_000000)
    public fun calculate_usdc_from_gold(oracle: &GoldPriceOracle, gold_amount: u64): u64 {
        let price = oracle.price_per_gram;
        // USDC (6 dec) = (aceGOLD (9 dec) * price (6 dec)) / 1e9
        ((gold_amount as u128) * (price as u128) / 1_000_000_000) as u64
    }
}
