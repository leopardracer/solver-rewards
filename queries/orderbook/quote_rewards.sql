with
{{excluded_quotes}}

winning_quotes as (
    select --noqa: ST06
        concat('0x', encode(oq.solver, 'hex')) as solver,
        oq.order_uid
    from trades as t
    inner join orders as o on order_uid = uid
    inner join order_quotes as oq on t.order_uid = oq.order_uid
    where
        (
            o.class = 'market'
            or (
                o.kind = 'sell'
                and (
                    oq.sell_amount - oq.gas_amount * oq.gas_price / oq.sell_token_price
                ) * oq.buy_amount >= o.buy_amount * oq.sell_amount
            )
            or (
                o.kind = 'buy'
                and o.sell_amount >= oq.sell_amount + oq.gas_amount * oq.gas_price / oq.sell_token_price
            )
        )
        and o.partially_fillable = 'f' -- the code above might fail for partially fillable orders
        and block_number >= {{start_block}}
        and block_number <= {{end_block}}
        and oq.solver != '\x0000000000000000000000000000000000000000'
        and oq.order_uid not in (select order_uid from excluded_quotes)
)

select
    solver,
    count(*) as num_quotes
from winning_quotes
group by solver
