{{ config(materialized='view') }}

with source as (
    select * from {{ source('example', 'raw_orders') }}
),

cleaned as (
    select
        o_orderkey as order_key,
        o_custkey as customer_key,
        o_orderstatus as order_status,
        o_totalprice as total_price,
        o_orderdate as order_date,
        o_orderpriority as order_priority,
        o_clerk as order_clerk,
        o_shippriority as ship_priority,
        o_comment as order_comment,
        
        -- Add derived fields
        date_trunc('month', o_orderdate) as order_month,
        date_trunc('year', o_orderdate) as order_year,
        
        -- Add audit fields
        current_timestamp() as loaded_at
        
    from source
)

select * from cleaned