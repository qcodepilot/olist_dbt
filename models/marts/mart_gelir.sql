with orders as (
    select *
      
    from {{ ref('stg_orders') }}
),
payments as (
    select *
    from {{ ref('stg_payments') }}
),
joined as (
    select
        o.order_id,
        o.order_purchase_timestamp,
        extract(year from o.order_purchase_timestamp) as year,
        extract(month from o.order_purchase_timestamp) as month,
        p.payment_type,
        p.payment_value
    from orders o
    join payments p 
        on o.order_id = p.order_id
),
final as (
    select
        year,
        month,
        payment_type,
        count(distinct order_id) as total_orders,
        sum(payment_value) as total_revenue,
        avg(payment_value) as avg_revenue_per_order
    from joined
    group by 1, 2, 3
)
select * from final