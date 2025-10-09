{{ config(materialized='table') }}

with monthly_revenue as (
    select
        date_trunc('month', o.order_date) as revenue_month,
        date_trunc('year', o.order_date) as revenue_year,
        
        -- Order metrics
        count(distinct o.order_key) as total_orders,
        count(distinct o.customer_key) as unique_customers,
        
        -- Revenue metrics from orders
        sum(o.total_price) as gross_revenue,
        avg(o.total_price) as avg_order_value,
        
        -- Revenue metrics from line items (more detailed)
        sum(l.extended_price) as sum_extended_price,
        sum(l.discounted_price) as net_revenue,
        sum(l.final_price) as final_revenue_with_tax,
        
        -- Discount analysis
        sum(l.extended_price * l.discount) as total_discount_given,
        avg(l.discount) as avg_discount_rate,
        
        -- Returns impact
        sum(case when l.return_flag = 'R' then l.final_price else 0 end) as returned_revenue,
        sum(case when l.return_flag = 'R' then 1 else 0 end) as returned_line_items,
        
        -- Market segment analysis
        sum(case when c.market_segment = 'BUILDING' then l.final_price else 0 end) as building_segment_revenue,
        sum(case when c.market_segment = 'AUTOMOBILE' then l.final_price else 0 end) as automobile_segment_revenue,
        sum(case when c.market_segment = 'MACHINERY' then l.final_price else 0 end) as machinery_segment_revenue,
        sum(case when c.market_segment = 'HOUSEHOLD' then l.final_price else 0 end) as household_segment_revenue,
        sum(case when c.market_segment = 'FURNITURE' then l.final_price else 0 end) as furniture_segment_revenue
        
    from {{ ref('stg_orders') }} o
    left join {{ ref('stg_lineitem') }} l on o.order_key = l.order_key
    left join {{ ref('stg_customer') }} c on o.customer_key = c.customer_key
    group by 1, 2
),

revenue_with_growth as (
    select
        *,
        -- Calculate month-over-month growth
        lag(net_revenue) over (order by revenue_month) as prev_month_revenue,
        case 
            when lag(net_revenue) over (order by revenue_month) > 0
            then (net_revenue - lag(net_revenue) over (order by revenue_month)) / lag(net_revenue) over (order by revenue_month) * 100
            else null
        end as mom_growth_pct,
        
        -- Calculate year-over-year growth
        lag(net_revenue, 12) over (order by revenue_month) as prev_year_revenue,
        case 
            when lag(net_revenue, 12) over (order by revenue_month) > 0
            then (net_revenue - lag(net_revenue, 12) over (order by revenue_month)) / lag(net_revenue, 12) over (order by revenue_month) * 100
            else null
        end as yoy_growth_pct,
        
        -- Calculate return rate
        case 
            when final_revenue_with_tax > 0 
            then returned_revenue / final_revenue_with_tax * 100
            else 0
        end as return_rate_pct,
        
        -- Calculate discount impact
        case 
            when sum_extended_price > 0 
            then total_discount_given / sum_extended_price * 100
            else 0
        end as discount_impact_pct
        
    from monthly_revenue
)

select * from revenue_with_growth
order by revenue_month