{{ config(materialized='table') }}

with business_summary as (
    select
        'total_customers' as metric_name,
        count(distinct customer_key) as metric_value,
        'count' as metric_type,
        current_date() as calculation_date
    from {{ ref('stg_customer') }}
    
    union all
    
    select
        'active_customers' as metric_name,
        count(distinct c.customer_key) as metric_value,
        'count' as metric_type,
        current_date() as calculation_date
    from {{ ref('stg_customer') }} c
    inner join {{ ref('stg_orders') }} o on c.customer_key = o.customer_key
    
    union all
    
    select
        'total_orders' as metric_name,
        count(*) as metric_value,
        'count' as metric_type,
        current_date() as calculation_date
    from {{ ref('stg_orders') }}
    
    union all
    
    select
        'total_revenue' as metric_name,
        sum(final_price) as metric_value,
        'currency' as metric_type,
        current_date() as calculation_date
    from {{ ref('stg_lineitem') }}
    
    union all
    
    select
        'avg_order_value' as metric_name,
        avg(total_price) as metric_value,
        'currency' as metric_type,
        current_date() as calculation_date
    from {{ ref('stg_orders') }}
    
    union all
    
    select
        'total_returned_items' as metric_name,
        count(*) as metric_value,
        'count' as metric_type,
        current_date() as calculation_date
    from {{ ref('stg_lineitem') }}
    where return_flag = 'R'
    
    union all
    
    select
        'return_rate_pct' as metric_name,
        sum(case when return_flag = 'R' then 1 else 0 end) / count(*) * 100 as metric_value,
        'percentage' as metric_type,
        current_date() as calculation_date
    from {{ ref('stg_lineitem') }}
    
    union all
    
    select
        'avg_discount_rate' as metric_name,
        avg(discount) * 100 as metric_value,
        'percentage' as metric_type,
        current_date() as calculation_date
    from {{ ref('stg_lineitem') }}
    
    union all
    
    select
        'avg_delivery_days' as metric_name,
        avg(delivery_days) as metric_value,
        'days' as metric_type,
        current_date() as calculation_date
    from {{ ref('stg_lineitem') }}
    where delivery_days is not null
),

market_segment_summary as (
    select
        concat('revenue_', lower(c.market_segment)) as metric_name,
        sum(l.final_price) as metric_value,
        'currency' as metric_type,
        current_date() as calculation_date
    from {{ ref('stg_customer') }} c
    inner join {{ ref('stg_orders') }} o on c.customer_key = o.customer_key
    inner join {{ ref('stg_lineitem') }} l on o.order_key = l.order_key
    group by c.market_segment
),

shipping_mode_summary as (
    select
        concat('shipments_', lower(replace(ship_mode, ' ', '_'))) as metric_name,
        count(*) as metric_value,
        'count' as metric_type,
        current_date() as calculation_date
    from {{ ref('stg_lineitem') }}
    where ship_mode is not null
    group by ship_mode
)

select * from business_summary
union all
select * from market_segment_summary  
union all
select * from shipping_mode_summary