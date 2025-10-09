{{ config(materialized='table') }}

with order_details as (
    select
        o.order_key,
        o.customer_key,
        o.order_status,
        o.order_date,
        o.order_priority,
        o.order_clerk,
        o.ship_priority,
        o.total_price as order_header_total,
        
        -- Customer info
        c.customer_name,
        c.market_segment,
        c.nation_key,
        
        -- Line item aggregations
        count(l.line_number) as total_line_items,
        sum(l.quantity) as total_quantity,
        sum(l.extended_price) as sum_extended_price,
        sum(l.discounted_price) as sum_discounted_price,
        sum(l.final_price) as sum_final_price,
        
        -- Discount and tax totals
        sum(l.extended_price * l.discount) as total_discount_amount,
        avg(l.discount) as avg_discount_rate,
        avg(l.tax) as avg_tax_rate,
        
        -- Shipping metrics
        min(l.ship_date) as first_ship_date,
        max(l.ship_date) as last_ship_date,
        avg(l.delivery_days) as avg_delivery_days,
        avg(l.days_late_early) as avg_days_late_early,
        
        -- Return metrics
        sum(case when l.return_flag = 'R' then 1 else 0 end) as returned_line_items,
        sum(case when l.return_flag = 'R' then l.final_price else 0 end) as returned_value
        
    from {{ ref('stg_orders') }} o
    left join {{ ref('stg_customer') }} c on o.customer_key = c.customer_key
    left join {{ ref('stg_lineitem') }} l on o.order_key = l.order_key
    group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
),

order_metrics as (
    select
        *,
        -- Calculate return rate for this order
        case 
            when total_line_items > 0 
            then returned_line_items / total_line_items * 100
            else 0
        end as return_rate_pct,
        
        -- Calculate discount rate
        case 
            when sum_extended_price > 0 
            then total_discount_amount / sum_extended_price * 100
            else 0
        end as discount_rate_pct,
        
        -- Shipping performance
        case 
            when avg_days_late_early > 0 then 'Late'
            when avg_days_late_early < 0 then 'Early'
            else 'On Time'
        end as shipping_performance,
        
        -- Order size classification
        case 
            when sum_final_price >= 300000 then 'Large'
            when sum_final_price >= 100000 then 'Medium'
            else 'Small'
        end as order_size_category
        
    from order_details
)

select * from order_metrics