{{ config(materialized='table') }}

-- Monthly business performance combining orders and line items
-- Shows revenue trends, shipping performance, and key business metrics

select
    date_trunc('month', o.order_date) as order_month,
    
    -- Volume metrics
    count(distinct o.order_key) as total_orders,
    count(distinct o.customer_key) as unique_customers,
    count(l.line_number) as total_line_items,
    sum(l.quantity) as total_quantity_sold,
    
    -- Revenue metrics  
    sum(o.total_price) as gross_revenue,
    sum(l.discounted_price) as net_revenue,
    sum(l.final_price) as revenue_with_tax,
    avg(o.total_price) as avg_order_value,
    
    -- Operational metrics
    avg(l.discount) as avg_discount_rate,
    round(sum(l.extended_price * l.discount) * 100.0 / sum(l.extended_price), 2) as discount_impact_percent,
    
    -- Returns and performance
    sum(case when l.return_flag = 'R' then 1 else 0 end) as returned_items,
    round(
        sum(case when l.return_flag = 'R' then 1 else 0 end) * 100.0 / count(l.line_number), 2
    ) as return_rate_percent,
    
    -- Shipping performance
    avg(l.delivery_days) as avg_delivery_days,
    sum(case when l.days_late_early > 0 then 1 else 0 end) as late_shipments,
    round(
        sum(case when l.days_late_early <= 0 then 1 else 0 end) * 100.0 / 
        count(case when l.ship_date is not null then 1 end), 2
    ) as on_time_delivery_percent,
    
    -- Market segment breakdown
    sum(case when c.market_segment = 'BUILDING' then l.final_price else 0 end) as building_revenue,
    sum(case when c.market_segment = 'AUTOMOBILE' then l.final_price else 0 end) as automobile_revenue,
    sum(case when c.market_segment = 'MACHINERY' then l.final_price else 0 end) as machinery_revenue

from {{ ref('stg_orders') }} o
left join {{ ref('stg_lineitem') }} l on o.order_key = l.order_key
left join {{ ref('stg_customer') }} c on o.customer_key = c.customer_key
group by date_trunc('month', o.order_date)
order by order_month