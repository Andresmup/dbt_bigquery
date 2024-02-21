{{config(materialized='view')}}

with tripdata as 
(
    select *,
        row_number() over(partition by dispatching_base_num, pickup_datetime) as rn
    from {{ source('staging', 'fhv_tripdata') }}
    where dispatching_base_num is not null
)

select
   -- identifiers
    {{ dbt_utils.generate_surrogate_key(['dispatching_base_num', 'pickup_datetime']) }} as fhvid,    
    {{ dbt.safe_cast("pulocationid", api.Column.translate_type("integer")) }} as pickup_locationid,
    {{ dbt.safe_cast("dolocationid", api.Column.translate_type("integer")) }} as dropoff_locationid,

    --dispatching
    dispatching_base_num,
    affiliated_base_number,

    -- timestamps
    cast(pickup_datetime as timestamp) as pickup_datetime,
    cast(dropoff_datetime as timestamp) as dropoff_datetime,

    --flag
    cast(sr_flag as numeric) as sr_flag

from tripdata
where 
    extract(year from cast(pickup_datetime as date)) = 2019
    and rn = 1


-- dbt build --select <model.sql> --vars '{'is_test_run: false}'
{% if var('is_test_run', default=false) %}

  limit 100

{% endif %}

