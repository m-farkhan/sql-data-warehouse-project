-- =============================================
-- GOLD LAYER: Data Warehouse (Star Schema)
-- =============================================

-- dim product
create table gold.dim_product (
    product_id    int primary key,
    product_name  varchar(100),
    category      varchar(50),
    brand         varchar(50),
    unit          varchar(20),
    cost_price    decimal
);

-- dim customer
create table gold.dim_customer (
    customer_id  int primary key,
    outlet_name  varchar(100),
    outlet_type  varchar(50),
    segment      varchar(50)
);

-- dim location
create table gold.dim_location (
    location_id  int primary key,
    city         varchar(50),
    province     varchar(50),
    region       varchar(50)
);

-- dim salesman
create table gold.dim_salesman (
    salesman_id    int primary key,
    salesman_name  varchar(100),
    area           varchar(50),
    team           varchar(30)
);

-- dim time
create table gold.dim_time (
    time_id  int primary key,
    date     date,
    day      int,
    week     int,
    month    int,
    quarter  varchar(10),
    year     int
);

-- fact sales
create table gold.fact_sales (
    sale_id      varchar(50) primary key,
    order_date   date,
    time_id      int,
    product_id   int,
    customer_id  int,
    location_id  int,
    salesman_id  int,
    quantity     int,
    unit_price   decimal,
    discount     decimal,
    total_amount decimal,
    created_at   timestamp default now(),
    foreign key (product_id)  references gold.dim_product(product_id),
    foreign key (customer_id) references gold.dim_customer(customer_id),
    foreign key (location_id) references gold.dim_location(location_id),
    foreign key (salesman_id) references gold.dim_salesman(salesman_id),
    foreign key (time_id)     references gold.dim_time(time_id)
);

-- audit log table
create table gold.fact_sales_audit (
    audit_id         serial primary key,
    sale_id          varchar(50),
    operation        text,
    old_quantity     int,
    new_quantity     int,
    old_unit_price   decimal,
    new_unit_price   decimal,
    old_discount     decimal,
    new_discount     decimal,
    old_total_amount decimal,
    new_total_amount decimal,
    changed_at       timestamp default now()
);