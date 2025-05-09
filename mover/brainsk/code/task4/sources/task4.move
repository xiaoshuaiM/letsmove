/// Module: task4
module task4::task4 {
    use sui::object::{Self, UID};
    use sui::balance::Balance;
    use sui::coin::{Self, Coin};
    use sui::transfer::{transfer, share_object, public_transfer};
    use sui::tx_context::{Self, sender};
    use sui::bcs;
    use faucetcoin::faucetcoin::FAUCETCOIN;
    use std::debug::print;
    use std::string::utf8;

    const ENotAllow: u64 = 0;
    const EInvalidStake: u64 = 1;
    const Rate: u64 = 2;
    const MaxStake: u64 = 100000000000000000;
    const MinStake: u64 = 10;

    // otw
    public struct TASK4 has drop {}

    // 奖金池，管理员为brainsk
    public struct PrizePool has key {
        id: UID,
        prize: Balance<FAUCETCOIN>,
        brainsk: address         // github id
    }

    // 用于创建、初始化奖金池，之后删除
    public struct PrizePoolCap has key {
        id: UID
    }

    // 创建Cap，并发送给brainsk
    fun init(_otw: TASK4, ctx: &mut TxContext) {
        let prize_pool_cap = PrizePoolCap {
            id: object::new(ctx)
        };
        transfer(prize_pool_cap, tx_context::sender(ctx));
    }

    // 用于创建奖金池，并注入初始奖金
    public entry fun initialize_pool(cap: PrizePoolCap, coin: Coin<FAUCETCOIN>, ctx: &mut TxContext) {
        let prize_pool = PrizePool {
            id: object::new(ctx),
            prize: coin.into_balance(),
            brainsk: sender(ctx)
        };
        share_object(prize_pool);
        let PrizePoolCap { id } = cap;
        object::delete(id);
    }

    // 给奖金池注入更多奖金，任何人都有权限
    public entry fun deposit(pool: &mut PrizePool, coin: Coin<FAUCETCOIN>) {
        coin::put(&mut pool.prize, coin)
    }

    // 在奖金池取出指定数量金额
    public entry fun withdraw(pool: &mut PrizePool, amount: u64, ctx: &mut TxContext) {
        assert!(pool.brainsk == sender(ctx), ENotAllow);
        let balance = pool.prize.split(amount);
        let coin = coin::from_balance(balance, ctx);
        public_transfer(coin, sender(ctx));
    }

    // 在奖金池取出所有奖金
    public fun withdraw_all(pool: &mut PrizePool, ctx: &mut TxContext) {
        // 确保调用者是奖金池的拥有者
        assert!(pool.brainsk == sender(ctx), ENotAllow);
        let balance = pool.prize.withdraw_all();
        let coin = coin::from_balance(balance, ctx);
        // 由于已经确认了调用者是奖金池的拥有者，这里不需要再次检查

        public_transfer(coin, sender(ctx));
    }

    // 查询奖金池中剩余的金额
    public fun query_prize(pool: &mut PrizePool):u64 {
        pool.prize.value()
    }

    // 通过交易hash的方式获取随机数
    fun random_num(ctx: &mut TxContext): u8 {
        let tx_digest = tx_context::digest(ctx);
        let tx_digest_u64= bcs::peel_u8(&mut bcs::new(*tx_digest));
        let random_index: u8 = tx_digest_u64 % 3;
        random_index
    }

    // 开始游戏
    public entry fun start_game(pool: &mut PrizePool, geuss_number: u8, stake: Coin<FAUCETCOIN>, ctx: &mut TxContext): bool {
        let balance = stake.into_balance();
        let value = balance.value();
        let mut res = false;
        assert!(value < MaxStake && value > MinStake, EInvalidStake);
        pool.prize.join(balance);
        let the_number = random_num(ctx);
        print(&utf8(b"The number is:"));
        print(&the_number);
        if (geuss_number == the_number) {
            let prize_value = pool.prize.split(Rate * value);
            let prize_coin = coin::from_balance(prize_value, ctx);
            public_transfer(prize_coin, sender(ctx));
            res = true;
        };
        res
    }
}