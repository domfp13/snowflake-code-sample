{{ config(materialized='view') }}

with source as (
    select * from {{ source('example', 'raw_lineitem') }}
),

cleaned as (
    select
        l_orderkey as order_key,
        l_partkey as part_key,
        l_suppkey as supplier_key,
        l_linenumber as line_number,
        l_quantity as quantity,
        l_extendedprice as extended_price,
        l_discount as discount,
        l_tax as tax,
        l_returnflag as return_flag,
        l_linestatus as line_status,
        l_shipdate as ship_date,
        l_commitdate as commit_date,
        l_receiptdate as receipt_date,
        l_shipinstruct as ship_instructions,
        l_shipmode as ship_mode,
        l_comment as line_comment,
        
        -- Add calculated fields
        l_extendedprice * (1 - l_discount) as discounted_price,
        l_extendedprice * (1 - l_discount) * (1 + l_tax) as final_price,
        
        -- Date fields for analysis
        date_trunc('month', l_shipdate) as ship_month,
        date_trunc('year', l_shipdate) as ship_year,
        
        -- Delivery performance
        datediff('day', l_commitdate, l_shipdate) as days_late_early,
        datediff('day', l_shipdate, l_receiptdate) as delivery_days,
        
        -- Add audit fields
        current_timestamp() as loaded_at
        
    from source
)

select * from cleaned