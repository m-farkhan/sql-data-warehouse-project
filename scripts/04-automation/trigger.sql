-- =============================================
-- AUTOMATION: Trigger
-- =============================================

-- create function
create or replace function gold.log_fact_sales_changes()
returns trigger
language plpgsql
as $$
begin
    if tg_op = 'INSERT' then
        insert into gold.fact_sales_audit
            (sale_id, operation, new_quantity, new_unit_price, new_discount, new_total_amount)
        values
            (new.sale_id, 'INSERT', new.quantity, new.unit_price, new.discount, new.total_amount);
        return new;

    elsif tg_op = 'UPDATE' then
        insert into gold.fact_sales_audit
            (sale_id, operation, old_quantity, new_quantity, old_unit_price, new_unit_price, old_discount, new_discount, old_total_amount, new_total_amount)
        values
            (new.sale_id, 'UPDATE', old.quantity, new.quantity, old.unit_price, new.unit_price, old.discount, new.discount, old.total_amount, new.total_amount);
        return new;

    elsif tg_op = 'DELETE' then
        insert into gold.fact_sales_audit
            (sale_id, operation, old_quantity, old_unit_price, old_discount, old_total_amount)
        values
            (old.sale_id, 'DELETE', old.quantity, old.unit_price, old.discount, old.total_amount);
        return old;

    end if;
end;
$$;

-- create trigger
create trigger trg_fact_sales_audit
after insert or update or delete on gold.fact_sales
for each row execute function gold.log_fact_sales_changes();