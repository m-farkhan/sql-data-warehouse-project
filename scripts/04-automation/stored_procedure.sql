-- =============================================
-- AUTOMATION: Stored Procedure
-- =============================================

create or replace procedure load_fmcg_pipeline()
language plpgsql
as $$
begin
    -- ==========================================
    -- step 1: validation
    -- ==========================================
    if (select count(*) from bronze.staging_sales) = 0 then
        raise exception 'Staging table is empty! Pipeline cancelled.';
    end if;

    raise notice 'Step 1: Validation completed, data exists in staging';

    -- ==========================================
    -- step 2: load silver layer
    -- ==========================================

    -- load clean product
    insert into silver.clean_product (product_name, category, brand, unit, cost_price)
    select distinct
        product_name,
        case product_name
            when 'Indomie Goreng'   then 'Mie Instan'
            when 'Indomie Rebus'    then 'Mie Instan'
            when 'Rinso Anti Noda'  then 'Deterjen'
            when 'Sunlight Jeruk'   then 'Sabun Cuci'
            when 'Aqua 600ml'       then 'Minuman'
            when 'Teh Botol Sosro'  then 'Minuman'
            when 'Good Day Coffee'  then 'Kopi'
            when 'Milo Activ'       then 'Minuman'
            when 'Pepsodent 190g'   then 'Personal Care'
            when 'Lifebuoy Sabun'   then 'Personal Care'
        end as category,
        brand,
        unit,
        cost_price::decimal
    from bronze.staging_sales
    where quantity is not null
      and unit_price is not null
      and total_amount is not null
      and quantity not like '-%'
    on conflict (product_name) do nothing;

    -- load clean customer
    insert into silver.clean_customer (outlet_name, outlet_type, segment)
    select distinct
        outlet_name,
        outlet_type,
        outlet_segment
    from bronze.staging_sales
    where outlet_name is not null
    on conflict (outlet_name) do nothing;

    -- load clean location
    insert into silver.clean_location (city, province, region)
    select distinct
        city,
        province,
        region
    from bronze.staging_sales
    where city is not null
    on conflict (city) do nothing;

    -- load clean salesman
    insert into silver.clean_salesman (salesman_name, area, team)
    select distinct
        salesman_name,
        salesman_area,
        salesman_team
    from bronze.staging_sales
    where salesman_name is not null
    on conflict (salesman_name, area) do nothing;

    -- load clean sales
    insert into silver.clean_sales (
        sale_id, order_date, product_id, customer_id, location_id,
        salesman_id, quantity, unit_price, discount, total_amount
    )
    select
        v.sale_id, v.order_date, v.product_id, v.customer_id, v.location_id,
        v.salesman_id, v.quantity, v.unit_price, v.discount, v.total_amount
    from (
        select
            s.sale_id,
            case
                when s.order_date like '__/__/____' then to_date(s.order_date, 'DD/MM/YYYY')
                when s.order_date like '__-__-____' then to_date(s.order_date, 'DD-MM-YYYY')
                when s.order_date like '% % %'      then to_date(s.order_date, 'Month DD YYYY')
                else s.order_date::date
            end as order_date,
            p.product_id,
            c.customer_id,
            l.location_id,
            sm.salesman_id,
            s.quantity::int as quantity,
            case
                when s.unit_price like '%Rp%'
                then replace(replace(s.unit_price, 'Rp', ''), '.', '')::decimal(15,2)
                else s.unit_price::decimal(15,2)
            end as unit_price,
            coalesce(s.discount::decimal(15,2), 0) as discount,
            case
                when s.total_amount like '%Rp%'
                then replace(replace(s.total_amount, 'Rp', ''), '.', '')::decimal(15,2)
                else s.total_amount::decimal(15,2)
            end as total_amount
        from bronze.staging_sales s
        join silver.clean_product p   on s.product_name  = p.product_name
        join silver.clean_customer c  on s.outlet_name   = c.outlet_name
        join silver.clean_location l  on s.city          = l.city
        join silver.clean_salesman sm on s.salesman_name = sm.salesman_name
        where
            s.quantity is not null
            and s.unit_price is not null
            and s.total_amount is not null
            and s.quantity not like '-%'
    ) v
    where
        v.quantity >= 1
        and v.unit_price >= 1.00
        and v.total_amount >= 1.00
    on conflict (sale_id) do nothing;

    raise notice 'Step 2: Silver layer loaded successfully';

    -- ==========================================
    -- step 3: load gold layer
    -- ==========================================

    -- load dim product
    insert into gold.dim_product (product_id, product_name, category, brand, unit, cost_price)
    select product_id, product_name, category, brand, unit, cost_price
    from silver.clean_product
    on conflict (product_id) do nothing;

    -- load dim customer
    insert into gold.dim_customer (customer_id, outlet_name, outlet_type, segment)
    select customer_id, outlet_name, outlet_type, segment
    from silver.clean_customer
    on conflict (customer_id) do nothing;

    -- load dim location
    insert into gold.dim_location (location_id, city, province, region)
    select location_id, city, province, region
    from silver.clean_location
    on conflict (location_id) do nothing;

    -- load dim salesman
    insert into gold.dim_salesman (salesman_id, salesman_name, area, team)
    select salesman_id, salesman_name, area, team
    from silver.clean_salesman
    on conflict (salesman_id) do nothing;

    -- load dim time
    insert into gold.dim_time (time_id, date, day, week, month, quarter, year)
    select distinct
        to_char(order_date, 'YYYYMMDD')::int as time_id,
        order_date,
        extract(day     from order_date),
        extract(week    from order_date),
        extract(month   from order_date),
        extract(quarter from order_date),
        extract(year    from order_date)
    from silver.clean_sales
    on conflict (time_id) do nothing;

    -- load fact sales
    insert into gold.fact_sales (
        sale_id, order_date, time_id, product_id, customer_id,
        location_id, salesman_id, quantity, unit_price, discount, total_amount
    )
    select
        s.sale_id,
        s.order_date,
        t.time_id,
        s.product_id,
        s.customer_id,
        s.location_id,
        s.salesman_id,
        s.quantity,
        s.unit_price,
        s.discount,
        s.total_amount
    from silver.clean_sales s
    join gold.dim_time t on to_char(s.order_date, 'YYYYMMDD')::int = t.time_id
    on conflict (sale_id) do nothing;

    raise notice 'Step 3: Gold layer loaded successfully';

    -- ==========================================
    -- step 4: refresh materialized views
    -- ==========================================

    refresh materialized view gold.mv_sales_by_month;
    refresh materialized view gold.mv_sales_by_product;
    refresh materialized view gold.mv_sales_by_region;

    raise notice 'Step 4: Materialized views refreshed successfully';

    -- ==========================================
    -- step 5: truncate staging
    -- ==========================================

    truncate bronze.staging_sales;

    raise notice 'Step 5: Staging table cleared successfully';

    -- ==========================================
    -- step 6: pipeline complete
    -- ==========================================

    raise notice 'Step 6: Pipeline load_fmcg_pipeline() completed at: %', now();

end;
$$;

call gold.load_fmcg_pipeline();

-- Cek dulu procedure ada di schema mana
SELECT routine_name, routine_schema
FROM information_schema.routines
WHERE routine_name = 'load_fmcg_pipeline';

-- Cukup truncate dim tables dengan CASCADE
-- fact_sales akan ikut ter-truncate otomatis
truncate gold.fact_sales_audit;
truncate gold.dim_product cascade;
truncate gold.dim_customer cascade;
truncate gold.dim_location cascade;
truncate gold.dim_salesman cascade;
truncate gold.dim_time cascade;

-- Baru truncate silver
truncate silver.clean_sales;
truncate silver.clean_product;
truncate silver.clean_customer;
truncate silver.clean_location;
truncate silver.clean_salesman;

select count(*) from bronze.staging_sales
union all
select count(*) from silver.clean_sales
union all
select count(*) from gold.fact_sales;

select 'bronze.staging_sales'  as tabel, count(*) as total from bronze.staging_sales
union all
select 'silver.clean_product',  count(*) from silver.clean_product
union all
select 'silver.clean_customer', count(*) from silver.clean_customer
union all
select 'silver.clean_location', count(*) from silver.clean_location
union all
select 'silver.clean_salesman', count(*) from silver.clean_salesman
union all
select 'silver.clean_sales',    count(*) from silver.clean_sales
union all
select 'gold.dim_product',      count(*) from gold.dim_product
union all
select 'gold.dim_customer',     count(*) from gold.dim_customer
union all
select 'gold.dim_location',     count(*) from gold.dim_location
union all
select 'gold.dim_salesman',     count(*) from gold.dim_salesman
union all
select 'gold.dim_time',         count(*) from gold.dim_time
union all
select 'gold.fact_sales',       count(*) from gold.fact_sales;
