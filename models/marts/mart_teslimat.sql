with orders as (
    select * FROM {{ ref('stg_orders') }}
),
final as (
    select
       order_id,
       order_purchase_timestamp,
       order_delivered_customer_date,
       order_estimated_delivery_date,

       date_diff(
        date(order_delivered_customer_date),
        date(order_purchase_timestamp),
        day
       ) as actual_delivery_time,
       date_diff(
        date(order_estimated_delivery_date),
        date(order_purchase_timestamp),
        day
       ) as estimated_delivery_time,

       case
        when order_delivered_customer_date > order_estimated_delivery_date then 'true'
        else 'false'
        end as late_delivery
    from orders
    where order_delivered_customer_date is not null
)
select * from final