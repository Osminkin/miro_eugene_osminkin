{{
    config(
        materialized='view'
    )
}}

select *
from {{ source('src_db', 'sessions') }}