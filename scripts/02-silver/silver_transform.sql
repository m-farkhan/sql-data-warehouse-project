-- =============================================
-- SILVER LAYER: Transform Bronze → Silver
-- =============================================

-- insert clean product (with correct category mapping)
insert into silver.clean_product (product_name, category, brand, unit, cost_price)
select distinct
    product_name,
    case product_name
        when 'Indomie Goreng'   			then 'Mie Instan'
        when 'Indomie Rebus'    			then 'Mie Instan'
        when 'Rinso Anti Noda'  			then 'Deterjen'
        when 'Sunlight Jeruk'   			then 'Sabun Cuci'
        when 'Aqua 600ml'       			then 'Minuman'
        when 'Teh Botol Sosro'  			then 'Minuman'
        when 'Good Day Coffee'  			then 'Kopi'
        when 'Milo Activ'       			then 'Minuman'
        when 'Pepsodent 190g'   			then 'Personal Care'
        when 'Lifebuoy Sabun'   			then 'Personal Care'
        when 'Chitato Sapi Panggang' 	then 'Snack'
				when 'Oreo Original'         	then 'Snack'
				when 'Energen Coklat'        	then 'Sereal'
				when 'Kopi Kapal Api'        	then 'Kopi'
				when 'Molto Ultra'           	then 'Deterjen'
				when 'Pantene Shampoo'       	then 'Personal Care'
				when 'Pop Mie Ayam'          	then 'Mie Instan'
				when 'Sprite 1.5L'           	then 'Minuman'
				when 'Pocari Sweat'          	then 'Minuman'
				when 'Ultra Milk Full Cream' 	then 'Minuman'
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

-- insert clean customer
insert into silver.clean_customer (outlet_name, outlet_type, segment)
select distinct
    outlet_name,
    outlet_type,
    outlet_segment
from bronze.staging_sales
where outlet_name is not null
on conflict (outlet_name) do nothing;

-- insert clean location
insert into silver.clean_location (city, province, region)
select distinct
    city,
    province,
    region
from bronze.staging_sales
where city is not null
on conflict (city) do nothing;

-- insert clean salesman
insert into silver.clean_salesman (salesman_name, area, team)
select distinct
    salesman_name,
    salesman_area,
    salesman_team
from bronze.staging_sales
where salesman_name is not null
on conflict (salesman_name, area) do nothing;

-- insert clean sales (with all transformations)
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