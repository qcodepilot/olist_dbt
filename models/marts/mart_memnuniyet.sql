with reviews as (
    select *
    from {{ ref('stg_reviews') }}
),
order_items as (
    select *
    from {{ ref('stg_order_items') }}
),
products as (
    select *
    from {{ ref('stg_products') }}
),
joined as (
    select
        r.review_id,
        r.order_id,
        r.review_score,
        p.product_category_name
    from reviews r
    join order_items oi 
        on r.order_id = oi.order_id
    join products p 
        on oi.product_id = p.product_id
),
final as (
    select
        product_category_name,
        avg(review_score) as avg_review_score,
        count(review_id) as total_reviews
    from joined
    group by 1
    having count(review_id) > 100
    order by avg_review_score asc
)
select * from final