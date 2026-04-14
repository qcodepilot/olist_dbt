with source as 
    (select *
    from {{ source('olist','olist_products_dataset') }}
),
renamed as (
    select
        product_id,
        product_category_name  
from source 
)
select * from renamed