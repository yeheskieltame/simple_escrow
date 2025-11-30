module simple_escrow::mock_usdc {
    use sui::coin;
    use sui::coin::TreasuryCap;
    use sui::coin_registry;

    /// One-time witness untuk token mock USDC (stablecoin).
    public struct MOCK_USDC has drop {}

    /// Init: buat USDC dan serahkan kapabilitas ke publisher.
    fun init(witness: MOCK_USDC, ctx: &mut TxContext) {
        let (builder, cap) = coin_registry::new_currency_with_otw(
            witness,
            6, // USDC pakai 6 decimals (sama seperti USDC asli)
            b"USDC".to_string(),
            b"Mock USDC".to_string(),
            b"Mock USD Coin Stablecoin".to_string(),
            b"".to_string(),
            ctx,
        );
        let metadata_cap = builder.finalize(ctx);
        transfer::public_transfer(cap, ctx.sender());
        transfer::public_transfer(metadata_cap, ctx.sender());
    }

    /// Mint USDC ke caller.
    public entry fun mint_usdc(
        cap: &mut TreasuryCap<MOCK_USDC>,
        amount: u64,
        ctx: &mut TxContext,
    ) {
        let minted = coin::mint(cap, amount, ctx);
        transfer::public_transfer(minted, ctx.sender());
    }
}
