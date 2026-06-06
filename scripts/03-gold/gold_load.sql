-- =============================================
-- GOLD LAYER: Load Silver → Gold
-- =============================================

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