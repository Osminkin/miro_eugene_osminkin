{{
    config(
        materialized='table',
        tags=["daily_run"]
    )
}}

with sessions    as (select * from {{ ref('stg_sessions') }})
   , conversions as (select * from {{ ref('stg_conversions') }})

select
    nvl(sessions.user_id,conversions.user_id) as user_id,
    sessions.time_started,
    sessions.is_paid,
    sessions.medium,
    conversions.registration_time,

    DATEDIFF(millisecond,sessions.time_started,conversions.registration_time) as duration_to_registration_ms,
    DATEDIFF(hour,sessions.time_started,conversions.registration_time) as duration_to_registration_hr,

    IFF(DATEDIFF(hour,sessions.time_started,conversions.registration_time) <= 12 -- under 12hrs
        and IFF(sessions.MEDIUM = 'PAID SEARCH',DATEDIFF(hour,sessions.time_started,conversions.registration_time) <= 3,TRUE)
        and IFF(sessions.MEDIUM = 'PAID SOCIAL',DATEDIFF(hour,sessions.time_started,conversions.registration_time) <= 1,TRUE),
            TRUE,FALSE) as is_within_life_span,

    IFF(sessions.MEDIUM not in ('DIRECT','OTHER','INVITES'),TRUE,FALSE) as is_live_session,
    IFF(DATEDIFF(MILLISECOND,sessions.time_started,conversions.registration_time) > 0,TRUE,FALSE) as is_before_registration
        
from sessions
full outer join conversions
    on conversions.user_id = sessions.user_id