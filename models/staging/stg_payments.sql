with source as (
    select *
    from {{ source('olist','olist_order_payments_dataset') }}
),
renamed as (
    select
        order_id,
        payment_type,
        payment_installments,
        payment_value
    from source
)

select * from renamed