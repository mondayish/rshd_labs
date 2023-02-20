do
$$
    declare
        column_record  record;
        table_id       oid;
        my_column_name text;
        column_number  text;
        column_type    text;
        column_type_id oid;
        column_comment text;
        column_constr  text;
        result         text;
    begin
        raise notice 'Таблица: %', :tab_name;
        raise notice 'No  Имя столбца    Атрибуты';
        raise notice '--- -------------- ------------------------------------------';
        select "oid" into table_id from ucheb.pg_catalog.pg_class where "relname" = :tab_name;
        for column_record in select * from ucheb.pg_catalog.pg_attribute where attrelid = table_id
            loop
                if column_record.attnum > 0 then
                    column_number = column_record.attnum;
                    my_column_name = column_record.attname;
                    column_type_id = column_record.atttypid;
                    select typname into column_type from ucheb.pg_catalog.pg_type where oid = column_type_id;

                    if column_record.atttypmod != -1 then
                        column_type = column_type || ' (' || column_record.atttypmod || ')';

                        --                         if column_type = 'int4' then
--                             column_type = 'NUMBER';
--                         end if;
                    end if;

                    if column_record.attnotnull then
                        column_type = column_type || ' NOT NULL';
                    end if;

                    select description
                    into column_comment
                    from ucheb.pg_catalog.pg_description
                    where objoid = table_id
                      and objsubid = column_record.attnum;
                    column_comment = '"' || column_comment || '"';

                    select string_agg(distinct pc.conname, ',')
                    from pg_constraint pc
                    where pc.conrelid = table_id
--                       and pc.conname ~* (column_record.attname)
--                       and pc.contype = 'c'
                    into column_constr;
--                     raise notice 'Constr: %', column_constr;

                    select format('%-3s %-14s %-8s %-2s %s', column_number, my_column_name, 'Type', ':', column_type)
                    into result;
                    raise notice '%', result;

                    if length(column_comment) > 0 then
                        select format('%-18s %-8s %-2s %s', '|', 'Comment', ':', column_comment) into result;
                        raise notice '%', result;
                    end if;

                    if column_constr is not null then
                        select format('%-18s %-8s %-2s %s %s', '.', ' ', ' ', 'Constr', column_constr) into result;
                        raise notice '%', result;
                    end if;
                end if;
            end loop;
    end
$$ LANGUAGE plpgsql;