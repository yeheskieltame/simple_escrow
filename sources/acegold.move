module simple_escrow::acegold {
    use sui::coin;
    use sui::coin::TreasuryCap;
    use sui::coin_registry;

    /// One-time witness untuk aceGOLD (synthetic gold token).
    /// Nilai 1:1 dengan harga emas dunia via Oracle.
    public struct ACEGOLD has drop {}

    /// Init: buat aceGOLD dan serahkan kapabilitas ke publisher.
    fun init(witness: ACEGOLD, ctx: &mut TxContext) {
        let (builder, cap) = coin_registry::new_currency_with_otw(
            witness,
            9, // 9 decimals untuk presisi tinggi
            b"aceGOLD".to_string(),
            b"SolAce Gold".to_string(),
            b"Synthetic Gold Token - Save in Gold, Pay in USDC".to_string(),
            b"".to_string(),
            ctx,
        );
        let metadata_cap = builder.finalize(ctx);
        transfer::public_transfer(cap, ctx.sender());
        transfer::public_transfer(metadata_cap, ctx.sender());
    }

    /// Mint aceGOLD (dipanggil saat user deposit USDC).
    public fun mint(
        cap: &mut TreasuryCap<ACEGOLD>,
        amount: u64,
        ctx: &mut TxContext,
    ): coin::Coin<ACEGOLD> {
        coin::mint(cap, amount, ctx)
    }

    /// Burn aceGOLD (dipanggil saat user bayar dengan USDC).
    public fun burn(
        cap: &mut TreasuryCap<ACEGOLD>,
        coin_to_burn: coin::Coin<ACEGOLD>,
    ) {
        coin::burn(cap, coin_to_burn);
    }

    /// Entry function untuk mint manual (testing).
    public entry fun mint_acegold(
        cap: &mut TreasuryCap<ACEGOLD>,
        amount: u64,
        ctx: &mut TxContext,
    ) {
        let minted = mint(cap, amount, ctx);
        transfer::public_transfer(minted, ctx.sender());
    }
}
