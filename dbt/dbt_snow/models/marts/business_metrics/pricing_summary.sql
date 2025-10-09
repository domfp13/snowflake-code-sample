{{ config(materialized='table') }}

-- This model is inspired by TPC-H Query 1 (Pricing Summary Report)
-- Provides pricing summary by return flag and line status

with pricing_summary as (
    select
        l.return_flag,
        l.line_status,
        
        -- Quantity metrics
        sum(l.quantity) as sum_qty,
        avg(l.quantity) as avg_qty,
        
        -- Price metrics  
        sum(l.extended_price) as sum_base_price,
        sum(l.discounted_price) as sum_disc_price,
        sum(l.final_price) as sum_charge,
        
        -- Average price metrics
        avg(l.extended_price) as avg_price,
        avg(l.discounted_price) as avg_disc_price,
        avg(l.final_price) as avg_charge,
        
        -- Discount metrics
        avg(l.discount) as avg_disc,
        sum(l.extended_price * l.discount) as total_discount_amount,
        
        -- Tax metrics
        avg(l.tax) as avg_tax,
        sum(l.discounted_price * l.tax) as total_tax_amount,
        
        -- Count of line items
        count(*) as count_order,
        
        -- Additional business metrics
        min(l.ship_date) as earliest_ship_date,
        max(l.ship_date) as latest_ship_date,
        
        -- Performance metrics
        avg(l.delivery_days) as avg_delivery_days,
        sum(case when l.days_late_early > 0 then 1 else 0 end) as late_deliveries,
        sum(case when l.days_late_early > 0 then 1 else 0 end) / count(*) * 100 as late_delivery_pct
        
    from {{ ref('stg_lineitem') }} l
    where l.ship_date <= dateadd(day, -90, current_date())  -- Similar to TPC-H query filter
    group by 1, 2
),

summary_with_ratios as (
    select
        *,
        -- Calculate discount impact
        case 
            when sum_base_price > 0 
            then (sum_base_price - sum_disc_price) / sum_base_price * 100
            else 0
        end as discount_impact_pct,
        
        -- Calculate tax impact  
        case 
            when sum_disc_price > 0 
            then total_tax_amount / sum_disc_price * 100
            else 0
        end as tax_impact_pct
        
    from pricing_summary
)

select * from summary_with_ratios
order by return_flag, line_status