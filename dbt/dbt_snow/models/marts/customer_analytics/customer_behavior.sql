{{ config(materialized='table') }}

with customer_line_metrics as (
    select
        c.customer_key,
        c.customer_name,
        c.market_segment,
        
        -- Line item aggregations
        count(l.order_key) as total_line_items,
        sum(l.quantity) as total_quantity_ordered,
        sum(l.extended_price) as total_extended_price,
        sum(l.discounted_price) as total_discounted_price,
        sum(l.final_price) as total_final_price,
        
        -- Average metrics
        avg(l.discount) as avg_discount_rate,
        avg(l.tax) as avg_tax_rate,
        avg(l.delivery_days) as avg_delivery_days,
        
        -- Return behavior
        sum(case when l.return_flag = 'R' then 1 else 0 end) as returned_items,
        sum(case when l.return_flag = 'R' then l.final_price else 0 end) as returned_value,
        
        -- Calculate return rate
        case 
            when count(l.order_key) > 0 
            then sum(case when l.return_flag = 'R' then 1 else 0 end) / count(l.order_key) * 100
            else 0
        end as return_rate_pct
        
    from {{ ref('stg_customer') }} c
    left join {{ ref('stg_orders') }} o on c.customer_key = o.customer_key
    left join {{ ref('stg_lineitem') }} l on o.order_key = l.order_key
    group by 1, 2, 3
)

select * from customer_line_metrics