{{
    config(
        materialized='table',
        tags=["daily_run"]
    )
}}

WITH sessions_users as (select * from {{ ref('int_sessions_users') }})

, pre_output as (
select
    t1.user_id,
    t1.registration_time,
    
    min(iff(t1.is_paid 
        and t1.is_within_life_span 
        and t1.is_live_session
        and t1.is_before_registration
        ,t1.time_started,null)) as first_paid_time,

    min_by(
        iff(t1.is_paid 
        and t1.is_within_life_span 
        and t1.is_live_session
        and t1.is_before_registration
        ,t1.medium,null),
        iff(t1.is_paid 
        and t1.is_within_life_span 
        and t1.is_live_session
        and t1.is_before_registration
        ,t1.time_started,null)) as first_paid_medium,
        
    min(iff(t1.is_paid=FALSE 
        and t1.is_within_life_span 
        and t1.is_live_session
        and t1.is_before_registration
        ,t1.time_started,null)) as first_organic_time,
        
    min_by(
        iff(t1.is_paid=FALSE 
        and t1.is_within_life_span 
        and t1.is_live_session
        and t1.is_before_registration
        ,t1.medium,null),
        iff(t1.is_paid=FALSE 
        and t1.is_within_life_span 
        and t1.is_live_session
        and t1.is_before_registration
        ,t1.time_started,null)) as first_organic_medium,
        
    min(iff(t1.medium='INVITES' 
        and t1.is_before_registration,
        t1.time_started,null)) as first_invites_time,
    min(iff(t1.medium='DIRECT'
        and t1.is_before_registration,
        t1.time_started,null)) as first_direct_time,
    min(iff(t1.medium='OTHER'
        and t1.is_before_registration,
        t1.time_started,null)) as first_other_time
    
from sessions_users as t1
group by 1,2
)

select
    case 
        when t1.first_paid_time is not null 
        then t1.first_paid_medium
        when t1.first_organic_time is not null 
        then t1.first_organic_medium
        when t1.first_direct_time is not null 
        then 'DIRECT'
        when t1.first_other_time is not null 
        then 'OTHER'
        when t1.first_invites_time is not null 
        then 'INVITES'
        else 'OTHER' end as acquisition_channel,
    *
from pre_output as t1
