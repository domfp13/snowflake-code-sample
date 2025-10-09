{{ config(materialized='table') }}

with customer_order_metrics as (
    select
        c.customer_key,
        c.customer_name,
        c.market_segment,
        c.account_balance,
        c.nation_key,
        
        -- Order metrics
        count(o.order_key) as total_orders,
        sum(o.total_price) as lifetime_value,
        avg(o.total_price) as avg_order_value,
        min(o.order_date) as first_order_date,
        max(o.order_date) as last_order_date,
        
        -- Calculate customer tenure in days
        datediff('day', min(o.order_date), max(o.order_date)) as customer_tenure_days,
        
        -- Order frequency
        case 
            when count(o.order_key) > 0 
            then datediff('day', min(o.order_date), max(o.order_date)) / nullif(count(o.order_key), 0)
            else null
        end as avg_days_between_orders,
        
        -- Recent activity
        datediff('day', max(o.order_date), current_date()) as days_since_last_order
        
    from {{ ref('stg_customer') }} c
    left join {{ ref('stg_orders') }} o on c.customer_key = o.customer_key
    group by 1, 2, 3, 4, 5
),

customer_segments as (
    select 
        *,
        -- Customer value segmentation
        case 
            when lifetime_value >= 300000 then 'High Value'
            when lifetime_value >= 150000 then 'Medium Value'
            when lifetime_value > 0 then 'Low Value'
            else 'No Orders'
        end as value_segment,
        
        -- Customer frequency segmentation
        case 
            when total_orders >= 20 then 'Frequent'
            when total_orders >= 10 then 'Regular'
            when total_orders >= 1 then 'Occasional'
            else 'No Orders'
        end as frequency_segment,
        
        -- Customer recency segmentation
        case 
            when days_since_last_order <= 365 then 'Active'
            when days_since_last_order <= 730 then 'At Risk'
            when days_since_last_order > 730 then 'Inactive'
            else 'New'
        end as recency_segment
        
    from customer_order_metrics
)

select * from customer_segments