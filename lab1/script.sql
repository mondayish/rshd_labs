do
$$
    declare
        column_record  record;
        table_id       oid;
        schema_id      oid;
        my_column_name text;
        column_number  smallint;
        column_type    text;
        column_type_id oid;
        column_comment text;
        column_constr  text[];
        constr_line    text;
        result         text;
    begin
        raise notice 'Таблица: %', :table_name;
        raise notice 'No  Имя столбца    Атрибуты';
        raise notice '--- -------------- ------------------------------------------';

        select oid into schema_id from pg_namespace where nspname = :schema_name;
        select oid into table_id from pg_class where relname = :table_name
                                                 and (schema_id is null or relnamespace = schema_id);
        if table_id is null then
            raise exception 'Table % not found', :table_name;
        end if;

        for column_record in select * from pg_attribute where attrelid = table_id
            loop
                if column_record.attnum > 0 then
                    column_number = column_record.attnum;
                    my_column_name = column_record.attname;
                    column_type_id = column_record.atttypid;
                    select typname into column_type from pg_type where oid = column_type_id;

                    if column_record.atttypmod != -1 then
                        column_type = column_type || ' (' || column_record.atttypmod || ')';
                    end if;

                    if column_record.attnotnull then
                        column_type = column_type || ' NOT NULL';
                    end if;

                    select description
                    into column_comment
                    from pg_description
                    where objoid = table_id
                      and objsubid = column_record.attnum;
                    column_comment = '"' || column_comment || '"';

                    select array_agg('"' || pc.conname || '" ' || pg_get_constraintdef(pc.oid))
                    from pg_constraint pc
                    where pc.conrelid = table_id
                      and column_number = any (pc.conkey)
                      and pc.contype = 'c'
                    into column_constr;

                    select format('%-3s %-14s %-8s %-2s %s', column_number, my_column_name, 'Type', ':', column_type)
                    into result;
                    raise notice '%', result;

                    if length(column_comment) > 0 then
                        select format('%-18s %-8s %-2s %s', '|', 'Comment', ':', column_comment) into result;
                        raise notice '%', result;
                    end if;

                    if column_constr is not null then
                        foreach constr_line in array column_constr loop
                            select format('%-18s %-8s %-2s %s', '|', 'Constr', ':', constr_line) into result;
                            raise notice '%', result;
                        end loop;
                    end if;
                end if;
            end loop;
    end
$$ LANGUAGE plpgsql;