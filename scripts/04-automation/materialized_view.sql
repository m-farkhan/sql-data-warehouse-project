-- =============================================
-- AUTOMATION: Materialized Views for Reporting
-- =============================================

-- sales by month
create materialized view gold.mv_sales_by_month as
select
    t.month,
    t.year,
    count(distinct s.sale_id) as total_orders,
    sum(s.quantity)           as total_quantity,
    sum(s.total_amount)       as total_revenue
from gold.fact_sales s
join gold.dim_time t on s.time_id = t.time_id
group by 1, 2;

-- sales by product
create materialized view gold.mv_sales_by_product as
select
    p.product_name,
    p.category,
    p.brand,
    count(distinct s.sale_id) as total_orders,
    sum(s.quantity)           as total_quantity,
    sum(s.total_amount)       as total_revenue
from gold.fact_sales s
join gold.dim_product p on s.product_id = p.product_id
group by 1, 2, 3;

-- sales by region
create materialized view gold.mv_sales_by_region as
select
    l.region,
    l.province,
    l.city,
    count(distinct s.sale_id) as total_orders,
    sum(s.quantity)           as total_quantity,
    sum(s.total_amount)       as total_revenue
from gold.fact_sales s
join gold.dim_location l on s.location_id = l.location_id
group by 1, 2, 3;