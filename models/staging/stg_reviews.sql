with source as (
    select *
    from {{ source('olist', 'olist_order_reviews_dataset') }}
),
renamed as (
    select distinct
    review_id,
    order_id,
    review_score,
    review_creation_date
    from source
)
select *from renamed