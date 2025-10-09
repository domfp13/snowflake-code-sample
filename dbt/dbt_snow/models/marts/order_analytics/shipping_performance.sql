{{ config(materialized='table') }}

with shipping_analysis as (
    select
        l.ship_mode,
        l.return_flag,
        l.line_status,
        
        -- Volume metrics
        count(*) as total_shipments,
        sum(l.quantity) as total_quantity_shipped,
        sum(l.final_price) as total_shipped_value,
        
        -- Performance metrics
        avg(l.delivery_days) as avg_delivery_days,
        avg(l.days_late_early) as avg_days_late_early,
        
        -- Late/Early shipments
        sum(case when l.days_late_early > 0 then 1 else 0 end) as late_shipments,
        sum(case when l.days_late_early < 0 then 1 else 0 end) as early_shipments,
        sum(case when l.days_late_early = 0 then 1 else 0 end) as on_time_shipments,
        
        -- Calculate performance percentages
        sum(case when l.days_late_early > 0 then 1 else 0 end) / count(*) * 100 as late_shipment_pct,
        sum(case when l.days_late_early <= 0 then 1 else 0 end) / count(*) * 100 as on_time_or_early_pct,
        
        -- Returns by shipping mode
        sum(case when l.return_flag = 'R' then 1 else 0 end) as returned_shipments,
        sum(case when l.return_flag = 'R' then l.final_price else 0 end) as returned_value,
        sum(case when l.return_flag = 'R' then 1 else 0 end) / count(*) * 100 as return_rate_pct
        
    from {{ ref('stg_lineitem') }} l
    where l.ship_date is not null
    group by 1, 2, 3
),

monthly_shipping_trends as (
    select
        l.ship_month,
        l.ship_mode,
        
        count(*) as monthly_shipments,
        sum(l.final_price) as monthly_shipped_value,
        avg(l.delivery_days) as avg_monthly_delivery_days,
        sum(case when l.return_flag = 'R' then 1 else 0 end) / count(*) * 100 as monthly_return_rate
        
    from {{ ref('stg_lineitem') }} l
    where l.ship_date is not null
    group by 1, 2
)

select 
    'summary' as analysis_type,
    ship_mode,
    return_flag,
    line_status,
    total_shipments,
    total_quantity_shipped,
    total_shipped_value,
    avg_delivery_days,
    avg_days_late_early,
    late_shipment_pct,
    on_time_or_early_pct,
    return_rate_pct,
    null as ship_month,
    null as monthly_shipments,
    null as monthly_shipped_value
from shipping_analysis

union all

select 
    'monthly_trend' as analysis_type,
    ship_mode,
    null as return_flag,
    null as line_status,
    null as total_shipments,
    null as total_quantity_shipped,
    null as total_shipped_value,
    avg_monthly_delivery_days as avg_delivery_days,
    null as avg_days_late_early,
    null as late_shipment_pct,
    null as on_time_or_early_pct,
    monthly_return_rate as return_rate_pct,
    ship_month,
    monthly_shipments,
    monthly_shipped_value
from monthly_shipping_trends