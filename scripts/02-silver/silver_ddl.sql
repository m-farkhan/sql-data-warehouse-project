-- =============================================
-- SILVER LAYER: Cleaned & Transformed Data
-- =============================================

-- clean product table
create table silver.clean_product (
	product_id 		serial primary key,
	product_name	varchar(100),
	category			varchar(50),
	brand					varchar(50),
	unit					varchar(20),
	cost_price		decimal
);

alter table silver.clean_product 
add constraint unique_product_name unique (product_name);

-- clean customer table
create table silver.clean_customer (
	customer_id	serial primary key,
	outlet_name	varchar(50),
	outlet_type	varchar(30),
	segment			varchar(30)
);

alter table silver.clean_customer
add constraint unique_customer_name	unique (outlet_name);

-- clean location table
create table silver.clean_location (
	location_id serial primary key,
	city				varchar(50),
	province		varchar(50),
	region			varchar(50)	
);

alter table silver.clean_location
add constraint unique_location_name unique (city);

-- clean salesman table
create table silver.clean_salesman (
	salesman_id		serial primary key,
	salesman_name	varchar(100),
	area					varchar(30),
	team					varchar(30)
);

alter table silver.clean_salesman
add constraint unique_salesman_name_area unique (salesman_name, area);

-- clean sales table
create table silver.clean_sales (
	sale_id				varchar(50) primary key,
	order_date		date,
	product_id		int,
	customer_id		int,
	location_id		int,
	salesman_id		int,
	quantity			int,
	unit_price		decimal,
	discount			decimal,
	total_amount	decimal,
	created_at		timestamp default now()
);