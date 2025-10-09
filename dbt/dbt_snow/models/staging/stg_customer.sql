{{ config(materialized='view') }}

with source as (
    select * from {{ source('example', 'raw_customer') }}
),

cleaned as (
    select
        c_custkey as customer_key,
        c_name as customer_name,
        c_address as customer_address,
        c_nationkey as nation_key,
        c_phone as phone_number,
        c_acctbal as account_balance,
        c_mktsegment as market_segment,
        c_comment as customer_comment,
        
        -- Add audit fields if available
        current_timestamp() as loaded_at
        
    from source
)

select * from cleaned