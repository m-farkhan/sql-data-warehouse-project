-- create database
create database fmcg_dw;
select current_database();

-- create schemas
create schema bronze;
create schema silver;
create schema gold;

select schema_name
from information_schema.schemata
where schema_name in ('bronze', 'silver', 'gold');