-- =============================================
-- BRONZE LAYER: Raw Data
-- =============================================

-- create staging table for bronze layer
create table bronze.staging_sales (
	sale_id					text,
	order_date			text,
	salesman_name		text,
	salesman_area		text,
	salesman_team		text,
	outlet_name			text,
	outlet_type			text,
	outlet_segment	text,
	city						text,
	province				text,
	region					text,
	product_name		text,
	brand						text,
	category				text,
	unit						text,
	quantity				text,
	unit_price			text,
	discount				text,
	total_amount		text
);

select * from bronze.staging_sales;

-- load raw data from CSV
copy bronze.staging_sales (sale_id, order_date, salesman_name, salesman_area, salesman_team, outlet_name, outlet_type, outlet_segment, city, province, region, product_name, brand, category, unit, cost_price, quantity, unit_price, discount, total_amount)
from 'C:\dataset\fmcg_sales_raw.csv'
with (
	format csv,
	header true,
	delimiter ','
);

truncate bronze.staging_sales;

-- check row count
select count(*) 
from bronze.staging_sales;

-- check data
select * 
from bronze.staging_sales 
limit 20;

-- check null values
select * 
from bronze.staging_sales
where quantity is null or total_amount is null;

select
    count(*) filter (where sale_id is null)         as null_sale_id,
    count(*) filter (where order_date is null)      as null_order_date,
    count(*) filter (where salesman_name is null)   as null_salesman_name,
    count(*) filter (where salesman_area is null)   as null_salesman_area,
    count(*) filter (where salesman_team is null)   as null_salesman_team,
    count(*) filter (where outlet_name is null)     as null_outlet_name,
    count(*) filter (where outlet_type is null)     as null_outlet_type,
    count(*) filter (where outlet_segment is null)  as null_outlet_segment,
    count(*) filter (where city is null)            as null_city,
    count(*) filter (where province is null)        as null_province,
    count(*) filter (where region is null)          as null_region,
    count(*) filter (where product_name is null)    as null_product_name,
    count(*) filter (where brand is null)           as null_brand,
    count(*) filter (where category is null)        as null_category,
    count(*) filter (where unit is null)            as null_unit,
    count(*) filter (where quantity is null)        as null_quantity,
    count(*) filter (where unit_price is null)      as null_unit_price,
    count(*) filter (where discount is null)        as null_discount,
    count(*) filter (where total_amount is null)    as null_total_amount
from bronze.staging_sales;

-- check inconsistent date format
select distinct order_date from bronze.staging_sales
where order_date not like '____-__-__'
order by order_date;
 
-- check negative values
select 
	sale_id, 
	quantity, 
	total_amount
from bronze.staging_sales
where quantity::text like '-%';

-- check amount with Rp format
select 
	sale_id, 
	unit_price, 
	total_amount
from bronze.staging_sales
where unit_price like 'Rp%';

-- check category typos
select 
	distinct category, 
	count(*) as total
from bronze.staging_sales
group by 1
order by 1;

-- check duplicates
select 
	sale_id, 
	count(*) as total
from bronze.staging_sales
group by 1
having count(*) > 1;

