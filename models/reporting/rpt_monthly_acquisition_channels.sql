{{
    config(
        materialized='table',
        tags=["daily_run"]
    )
}}

with acquisitions_users as (select * from {{ ref('int_acquisitions_users') }})

select
    date_trunc(month,t1.registration_time::date) as date_month,
    t1.acquisition_channel,
    count(distinct t1.user_id) as user_count
from acquisitions_users as t1
group by all