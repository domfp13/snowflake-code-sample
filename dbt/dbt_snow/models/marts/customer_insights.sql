{{ config(materialized='table') }}

-- Customer analysis combining all three staging tables
-- Shows customer lifetime value, order patterns, and key metrics

select
    c.customer_key,
    c.customer_name,
    c.market_segment,
    c.account_balance,
    
    -- Order summary metrics
    count(distinct o.order_key) as total_orders,
    sum(o.total_price) as lifetime_value,
    avg(o.total_price) as avg_order_value,
    min(o.order_date) as first_order_date,
    max(o.order_date) as last_order_date,
    
    -- Line item details
    count(l.line_number) as total_line_items,
    sum(l.quantity) as total_quantity_ordered,
    sum(l.final_price) as total_revenue_with_tax,
    avg(l.discount) as avg_discount_rate,
    
    -- Returns analysis
    sum(case when l.return_flag = 'R' then 1 else 0 end) as returned_items,
    round(
        sum(case when l.return_flag = 'R' then 1 else 0 end) * 100.0 / nullif(count(l.line_number), 0), 2
    ) as return_rate_percent,
    
    -- Customer classification
    case 
        when sum(o.total_price) >= 500000 then 'High Value'
        when sum(o.total_price) >= 200000 then 'Medium Value'
        when sum(o.total_price) > 0 then 'Low Value'
        else 'No Orders'
    end as customer_segment

from {{ ref('stg_customer') }} c
left join {{ ref('stg_orders') }} o on c.customer_key = o.customer_key  
left join {{ ref('stg_lineitem') }} l on o.order_key = l.order_key
group by c.customer_key, c.customer_name, c.market_segment, c.account_balance