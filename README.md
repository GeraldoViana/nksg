# NKSG: PL/SQL Simple Generator
### Generates Table CRUD PL/SQL Packages API

This hasn't by any means, the intention to be complete.

My goal here is to minimize the task of writing DMLs for every table on a system.

I've always liked and forced a single point of DMLs events in my PL/SQL codes,  
and every piece of it elsewhere just references this API.

_En plus_, when you are able to catch invalid data before hitting the SQL Engine is always a good way to go.

Working with a predefined PL/SQL structures(records/arrays) that mimics your  
table columns, is not all that pain when you need update your model.

When modeling my own data, I always stick with the ID/PID pair:

```sql
drop table r4v_customer cascade constraints purge;
drop table r4v_invoice  cascade constraints purge;

create table r4v_customer (
  id               number(*,0)   not null enable,
  first_name       varchar2(50)  not null enable,
  last_name        varchar2(50)  not null enable,
  email            varchar2(150) not null enable
);

create unique index r4v_customer on r4v_customer (id);
alter table r4v_customer add constraint r4v_customer primary key (id) using index enable;

create table r4v_invoice (
  id               number(*,0)  not null enable,
  pid_customer     number(*,0)  not null enable,
  invoice_date     date         not null enable,
  invoice_amount   number(*,2)  not null enable
);

create unique index r4v_invoice on r4v_invoice (id);
create index r4v_invoice_n1 on r4v_invoice (pid_customer);
alter table r4v_invoice add constraint r4v_invoice primary key (id) using index enable;
alter table r4v_invoice add constraint r4v_invoice_fk1 foreign key (pid_customer) references r4v_customer (id) enable;
```

:point_up: _Notice the unique index name and constraint name for primary key has the same name as table,  
but it's ok as they reside in different namespace._

Running the procedure overload from NKSG_DMLAPI:

```sql
declare
  lc__    constant varchar2(100) := 'Anonymous PL/SQL Block';
  nl      constant varchar2(30) := '
';
begin
  dbms_output.enable(buffer_size => 1e6);
  -- Package Specification
  nksg_dmlapi.dml_spec(fv_table   => 'R4V_CUSTOMER',
                       fv_replace => true);
  nksg_dmlapi.dml_spec(fv_table   => 'R4V_INVOICE',
                       fv_replace => true);
  -- Package Body
  nksg_dmlapi.dml_body(fv_table   => 'R4V_CUSTOMER',
                       fv_replace => true);
  nksg_dmlapi.dml_body(fv_table   => 'R4V_INVOICE',
                       fv_replace => true);
exception when others then
  raise_application_error(-20777, lc__ || nl || dbms_utility.format_error_stack);
end;
/

PL/SQL procedure successfully completed.
``` 

It will produce:

```sql
create or replace package r4v_customer_dml
authid current_user
is
  ------------------------------------------------------------------
  -- NKSG: PL/SQL Simple Generator
  ------------------------------------------------------------------
  --  (c) Copyright 2017 Geraldo Viana (r4vrya@gmail.com)
  --
  --  Licensed under the Apache License, Version 2.0 (the "License"):
  --  you may not use this file except in compliance with the License.
  --  You may obtain a copy of the License at
  --
  --      http://www.apache.org/licenses/LICENSE-2.0
  --
  --  Unless required by applicable law or agreed to in writing, software
  --  distributed under the License is distributed on an "AS IS" BASIS,
  --  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  --  See the License for the specific language governing permissions and
  --  limitations under the License.
  ------------------------------------------------------------------
  -- R4V_CUSTOMER_DML: R4V_CUSTOMER Simple CRUD API
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  ------------------------ Declare Session -------------------------
  ------------------------------------------------------------------
  gc_limit   constant pls_integer := 1e2; --FORALL collection limit: 100

  -- pl/sql subtypes
  subtype plstring    is varchar2(32767);
  subtype plraw       is raw(32767);

  -- pl/sql types
  type weak_refcursor is ref cursor;
  type plstring_list  is table of plstring index by pls_integer;
  type urowid_list    is table of urowid   index by pls_integer;

  -- API types
  type RecID is record(r#wid    urowid,
                       id       number(38));
  type ArrID is table of RecID index by pls_integer;

  type RecData is record(r#wid         urowid,
                         id            number(38),            -- PK 1/1
                         first_name    varchar2(50 char),
                         last_name     varchar2(50 char),
                         email         varchar2(150 char));
  type ArrData is table of RecData index by pls_integer;

  ------------------------------------------------------------------
  ----------------------- Subprogram Session -----------------------
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  -- EXISTS_ROW
  ------------------------------------------------------------------
  function exists_row(fr_id  in RecID)
    return boolean;
  ------------------------------------------------------------------
  function exists_row(fr_data  in RecData)
    return boolean;

  ------------------------------------------------------------------
  -- SELECT_ROW
  ------------------------------------------------------------------
  procedure select_row(fr_data  in out nocopy RecData,
                       fv_lock  in boolean default false);

  ------------------------------------------------------------------
  -- INSERT_ROW
  ------------------------------------------------------------------
  procedure insert_row(fr_data  in out nocopy RecData);

  ------------------------------------------------------------------
  -- INSERT_ALL
  ------------------------------------------------------------------
  procedure insert_all(ft_data    in out nocopy ArrData,
                       fv_rebind  in boolean default false);

  ------------------------------------------------------------------
  -- LOCK_ROW
  ------------------------------------------------------------------
  procedure lock_row(fr_id  in RecID);
  ------------------------------------------------------------------
  procedure lock_row(fr_data  in RecData);

  ------------------------------------------------------------------
  -- LOCK_ALL
  ------------------------------------------------------------------
  procedure lock_all(ft_id  in ArrID);
  ------------------------------------------------------------------
  procedure lock_all(ft_data  in ArrData);

  ------------------------------------------------------------------
  -- UPDATE_ROW
  ------------------------------------------------------------------
  procedure update_row(fr_data  in out nocopy RecData);

  ------------------------------------------------------------------
  -- UPDATE_ALL
  ------------------------------------------------------------------
  procedure update_all(ft_data    in out nocopy ArrData,
                       fv_rebind  in boolean default false);

  ------------------------------------------------------------------
  -- DELETE_ROW
  ------------------------------------------------------------------
  procedure delete_row(fr_id  in RecID);
  ------------------------------------------------------------------
  procedure delete_row(fr_data  in RecData);

  ------------------------------------------------------------------
  -- DELETE_ALL
  ------------------------------------------------------------------
  procedure delete_all(ft_id  in ArrID);
  ------------------------------------------------------------------
  procedure delete_all(ft_data  in ArrData);

  ------------------------------------------------------------------
  -- IS_NULL
  ------------------------------------------------------------------
  function is_null(fr_id  in RecID)
    return boolean;
  ------------------------------------------------------------------
  function is_null(fr_data  in RecData)
    return boolean;

  ------------------------------------------------------------------
  -- IS_EQUAL
  ------------------------------------------------------------------
  function is_equal(fr_old  in RecID,
                    fr_new  in RecID)
    return boolean;
  ------------------------------------------------------------------
  function is_equal(fr_old  in RecData,
                    fr_new  in RecData)
    return boolean;

  ------------------------------------------------------------------
  -- IS_SAME
  ------------------------------------------------------------------
  function is_same(fr_old  in RecID,
                   fr_new  in RecID)
    return boolean;
  ------------------------------------------------------------------
  function is_same(fr_old  in RecData,
                   fr_new  in RecData)
    return boolean;

end r4v_customer_dml;
```
```sql
create or replace package r4v_invoice_dml
authid current_user
is
  ------------------------------------------------------------------
  -- NKSG: PL/SQL Simple Generator
  ------------------------------------------------------------------
  --  (c) Copyright 2017 Geraldo Viana (r4vrya@gmail.com)
  --
  --  Licensed under the Apache License, Version 2.0 (the "License"):
  --  you may not use this file except in compliance with the License.
  --  You may obtain a copy of the License at
  --
  --      http://www.apache.org/licenses/LICENSE-2.0
  --
  --  Unless required by applicable law or agreed to in writing, software
  --  distributed under the License is distributed on an "AS IS" BASIS,
  --  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  --  See the License for the specific language governing permissions and
  --  limitations under the License.
  ------------------------------------------------------------------
  -- R4V_INVOICE_DML: R4V_INVOICE Simple CRUD API
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  ------------------------ Declare Session -------------------------
  ------------------------------------------------------------------
  gc_limit   constant pls_integer := 1e2; --FORALL collection limit: 100

  -- pl/sql subtypes
  subtype plstring    is varchar2(32767);
  subtype plraw       is raw(32767);

  -- pl/sql types
  type weak_refcursor is ref cursor;
  type plstring_list  is table of plstring index by pls_integer;
  type urowid_list    is table of urowid   index by pls_integer;

  -- API types
  type RecID is record(r#wid    urowid,
                       id       number(38));
  type ArrID is table of RecID index by pls_integer;

  type RecData is record(r#wid             urowid,
                         id                number(38),      -- PK 1/1
                         pid_customer      number(38),
                         invoice_date      date,
                         invoice_amount    number(38,2));
  type ArrData is table of RecData index by pls_integer;

  ------------------------------------------------------------------
  ----------------------- Subprogram Session -----------------------
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  -- EXISTS_ROW
  ------------------------------------------------------------------
  function exists_row(fr_id  in RecID)
    return boolean;
  ------------------------------------------------------------------
  function exists_row(fr_data  in RecData)
    return boolean;

  ------------------------------------------------------------------
  -- SELECT_ROW
  ------------------------------------------------------------------
  procedure select_row(fr_data  in out nocopy RecData,
                       fv_lock  in boolean default false);

  ------------------------------------------------------------------
  -- INSERT_ROW
  ------------------------------------------------------------------
  procedure insert_row(fr_data  in out nocopy RecData);

  ------------------------------------------------------------------
  -- INSERT_ALL
  ------------------------------------------------------------------
  procedure insert_all(ft_data    in out nocopy ArrData,
                       fv_rebind  in boolean default false);

  ------------------------------------------------------------------
  -- LOCK_ROW
  ------------------------------------------------------------------
  procedure lock_row(fr_id  in RecID);
  ------------------------------------------------------------------
  procedure lock_row(fr_data  in RecData);

  ------------------------------------------------------------------
  -- LOCK_ALL
  ------------------------------------------------------------------
  procedure lock_all(ft_id  in ArrID);
  ------------------------------------------------------------------
  procedure lock_all(ft_data  in ArrData);

  ------------------------------------------------------------------
  -- UPDATE_ROW
  ------------------------------------------------------------------
  procedure update_row(fr_data  in out nocopy RecData);

  ------------------------------------------------------------------
  -- UPDATE_ALL
  ------------------------------------------------------------------
  procedure update_all(ft_data    in out nocopy ArrData,
                       fv_rebind  in boolean default false);

  ------------------------------------------------------------------
  -- DELETE_ROW
  ------------------------------------------------------------------
  procedure delete_row(fr_id  in RecID);
  ------------------------------------------------------------------
  procedure delete_row(fr_data  in RecData);

  ------------------------------------------------------------------
  -- DELETE_ALL
  ------------------------------------------------------------------
  procedure delete_all(ft_id  in ArrID);
  ------------------------------------------------------------------
  procedure delete_all(ft_data  in ArrData);

  ------------------------------------------------------------------
  -- IS_NULL
  ------------------------------------------------------------------
  function is_null(fr_id  in RecID)
    return boolean;
  ------------------------------------------------------------------
  function is_null(fr_data  in RecData)
    return boolean;

  ------------------------------------------------------------------
  -- IS_EQUAL
  ------------------------------------------------------------------
  function is_equal(fr_old  in RecID,
                    fr_new  in RecID)
    return boolean;
  ------------------------------------------------------------------
  function is_equal(fr_old  in RecData,
                    fr_new  in RecData)
    return boolean;

  ------------------------------------------------------------------
  -- IS_SAME
  ------------------------------------------------------------------
  function is_same(fr_old  in RecID,
                   fr_new  in RecID)
    return boolean;
  ------------------------------------------------------------------
  function is_same(fr_old  in RecData,
                   fr_new  in RecData)
    return boolean;

end r4v_invoice_dml;
```
```sql
create or replace package body r4v_customer_dml
is
  ------------------------------------------------------------------
  -- NKSG: PL/SQL Simple Generator
  ------------------------------------------------------------------
  --  (c) Copyright 2017 Geraldo Viana (r4vrya@gmail.com)
  --
  --  Licensed under the Apache License, Version 2.0 (the "License"):
  --  you may not use this file except in compliance with the License.
  --  You may obtain a copy of the License at
  --
  --      http://www.apache.org/licenses/LICENSE-2.0
  --
  --  Unless required by applicable law or agreed to in writing, software
  --  distributed under the License is distributed on an "AS IS" BASIS,
  --  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  --  See the License for the specific language governing permissions and
  --  limitations under the License.
  ------------------------------------------------------------------
  -- R4V_CUSTOMER_DML: R4V_CUSTOMER Simple CRUD API
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  ------------------------ Declare Session -------------------------
  ------------------------------------------------------------------
  -- Local constants
  nl       constant varchar2(3) := '
';

  -- Exceptions
  lock_timeout     exception;
  pragma exception_init(lock_timeout, -30006);    -- ORA-30006: resource busy; acquire with WAIT timeout expired
  lock_nowait      exception;
  pragma exception_init(lock_nowait, -54);        -- ORA-00054: resource busy and acquire with NOWAIT specified
  dml_error        exception;
  pragma exception_init(dml_error, -24381);       -- ORA-24381: error(s) in array DML

  -- Stateful Scalars/Containers
  --gt_urowid    urowid_list;

  ------------------------------------------------------------------
  ------------------------ Private Session -------------------------
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  -- BULK_EXCEPTION_PVT
  -- *** TODO ***
  ------------------------------------------------------------------
  --procedure bulk_exception_pvt(ft_error  in out nocopy plstring_list)
  --is
  --  lc__    constant varchar2(100) := $$plsql_unit || '.BULK_EXCEPTION_PVT:';
  --  j                pls_integer;
  --begin
  --  for i in 1 .. sql%bulk_exceptions.count loop
  --    j := sql%bulk_exceptions(i).error_index;
  --    ft_error(j) := sqlerrm(-sql%bulk_exceptions(i).error_code);
  --  end loop;
  --exception when others then
  --  raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  --end bulk_exception_pvt;

  ------------------------------------------------------------------
  -- INSPECT_DATA_PVT
  ------------------------------------------------------------------
  procedure inspect_data_pvt(fr_data  in out nocopy RecData)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.INSPECT_DATA_PVT:';
  begin
    if (fr_data.email is null) then
      raise_application_error(-20888, 'fr_data.email argument cannot be null:' || $$plsql_line);
    elsif (fr_data.first_name is null) then
      raise_application_error(-20888, 'fr_data.first_name argument cannot be null:' || $$plsql_line);
    elsif (fr_data.id is null) then
      raise_application_error(-20888, 'fr_data.id argument cannot be null:' || $$plsql_line);
    elsif (fr_data.last_name is null) then
      raise_application_error(-20888, 'fr_data.last_name argument cannot be null:' || $$plsql_line);
    end if;
    -- include defaults and sanities below this line...
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end inspect_data_pvt;

  ------------------------------------------------------------------
  -- INSPECT_ID_PVT
  ------------------------------------------------------------------
  procedure inspect_id_pvt(fr_id  in RecID)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.INSPECT_ID_PVT:';
  begin
    if (fr_id.r#wid is null) then
      raise_application_error(-20888, 'fr_id.r#wid argument cannot be null:' || $$plsql_line);
    elsif (fr_id.id is null) then
      raise_application_error(-20888, 'fr_id.id argument cannot be null:' || $$plsql_line);
    end if;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end inspect_id_pvt;

  ------------------------------------------------------------------
  -- SELECT_ROW_PVT
  ------------------------------------------------------------------
  procedure select_row_pvt(fr_data  in out nocopy RecData)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.SELECT_ROW_PVT:';
    lv_refcur        weak_refcursor;
  begin
    open lv_refcur for
    select --+ choose
           a.rowid,                                                                             --000 urowid
           a.id,                                                                                --001 number(38)
           a.first_name,                                                                        --002 varchar2(50 char)
           a.last_name,                                                                         --003 varchar2(50 char)
           a.email                                                                              --004 varchar2(150 char)
      from r4v_customer    a
     where 1e1 = 1e1
       and (fr_data.r#wid is null or a.rowid = fr_data.r#wid)                                   --000 urowid
       and a.id = fr_data.id;                                                                   --001 number(38)
    fetch lv_refcur into fr_data;
    close lv_refcur;
  exception when others then
    if (lv_refcur%isopen) then
      close lv_refcur;
    end if;
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end select_row_pvt;

  ------------------------------------------------------------------
  -- SELECT_LOCKING_PVT
  ------------------------------------------------------------------
  procedure select_locking_pvt(fr_data  in out nocopy RecData)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.SELECT_LOCKING_PVT:';
    lv_refcur        weak_refcursor;
  begin
    open lv_refcur for
    select --+ choose
           a.rowid,                                                                             --000 urowid
           a.id,                                                                                --001 number(38)
           a.first_name,                                                                        --002 varchar2(50 char)
           a.last_name,                                                                         --003 varchar2(50 char)
           a.email                                                                              --004 varchar2(150 char)
      from r4v_customer    a
     where 1e1 = 1e1
       and (fr_data.r#wid is null or a.rowid = fr_data.r#wid)                                   --000 urowid
       and a.id = fr_data.id                                                                    --001 number(38)
       for update wait 4;
    fetch lv_refcur into fr_data;
    close lv_refcur;
  exception when others then
    if (lv_refcur%isopen) then
      close lv_refcur;
    end if;
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end select_locking_pvt;

  ------------------------------------------------------------------
  -- EXISTS_ROW_PVT
  ------------------------------------------------------------------
  function exists_row_pvt(fr_id  in RecID)
    return boolean
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.EXISTS_ROW_PVT:';
    lv_refcur       weak_refcursor;
    lv_null         varchar2(1);
    lv_found        boolean := false;
  begin
    open lv_refcur for
    select --+ rowid(a)
           null
      from r4v_customer    a
     where 1e1 = 1e1
       and (fr_id.r#wid is null or a.rowid = fr_id.r#wid)                                       --000 urowid
       and a.id = fr_id.id;                                                                     --001 number(38)
    fetch lv_refcur into lv_null;
    lv_found := lv_refcur%found;
    close lv_refcur;
    return lv_found;
  exception when others then
    if (lv_refcur%isopen) then
      close lv_refcur;
    end if;
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end exists_row_pvt;

  ------------------------------------------------------------------
  -- DELETE_ROW_PVT
  ------------------------------------------------------------------
  procedure delete_row_pvt(fr_id  in RecID)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.DELETE_ROW_PVT:';
  begin
    delete --+ rowid(a)
      from r4v_customer    a
     where 1e1 = 1e1
       and a.rowid = fr_id.r#wid                                                                --000 urowid
       and a.id = fr_id.id;                                                                     --001 number(38)
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end delete_row_pvt;

  ------------------------------------------------------------------
  -- UPDATE_ROW_PVT
  ------------------------------------------------------------------
  procedure update_row_pvt(fr_data  in out nocopy RecData)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.UPDATE_ROW_PVT:';
  begin
    update --+ rowid(a)
           r4v_customer    a
       set -- set-list
           a.first_name = fr_data.first_name,                                                   --002 varchar2(50 char)
           a.last_name = fr_data.last_name,                                                     --003 varchar2(50 char)
           a.email = fr_data.email                                                              --004 varchar2(150 char)
     where 1e1 = 1e1
       and a.rowid = fr_data.r#wid                                                              --000 urowid
       and a.id = fr_data.id                                                                    --001 number(38)
    returning
           rowid,                                                                               --000 urowid
           id,                                                                                  --001 number(38)
           first_name,                                                                          --002 varchar2(50 char)
           last_name,                                                                           --003 varchar2(50 char)
           email                                                                                --004 varchar2(150 char)
      into
           fr_data.r#wid,                                                                       --000 urowid
           fr_data.id,                                                                          --001 number(38)
           fr_data.first_name,                                                                  --002 varchar2(50 char)
           fr_data.last_name,                                                                   --003 varchar2(50 char)
           fr_data.email;                                                                       --004 varchar2(150 char)
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end update_row_pvt;

  ------------------------------------------------------------------
  -- LOCK_ROW_PVT
  ------------------------------------------------------------------
  procedure lock_row_pvt(fr_id  in RecID)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.LOCK_ROW_PVT:';
    lv_refcur        weak_refcursor;
  begin
    begin
      open lv_refcur for
      select --+ rowid(a)
             null
        from r4v_customer    a
       where 1e1 = 1e1
         and a.rowid = fr_id.r#wid                                                              --000 urowid
         and a.id = fr_id.id                                                                    --001 number(38)
      for update wait 4;
      close lv_refcur;
    exception
      when lock_nowait or lock_timeout then
        raise_application_error(-20888, 'rowid[' || fr_id.r#wid
                                || '] locked by another session:' || $$plsql_line);
      when others then
        raise;
    end;
  exception when others then
    if (lv_refcur%isopen) then
      close lv_refcur;
    end if;
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end lock_row_pvt;

  ------------------------------------------------------------------
  -- LOCK_ALL_PVT
  -- *** TODO ***
  ------------------------------------------------------------------
  --procedure lock_all_pvt
  --is
  --  lc__    constant varchar2(100) := $$plsql_unit || '.LOCK_ALL_PVT:';
  --  lv_refcur        weak_refcursor;
  --begin
  --  begin
  --    open lv_refcur for
  --    select --+ rowid(a)
  --           null
  --      from r4v_customer    a
  --     where 1e1 = 1e1
  --       and (a.rowid, a.id) in (select --+ dynamic_sampling(p, 10)
  --                                      chartorowid(p.map_item),
  --                                      to_number(p.map_value)
  --                                 from table(nksg_dmlapi.pipe_rowid)    p
  --                                where 1e1 = 1e1)
  --       for update wait 4;
  --    close lv_refcur;
  --  exception
  --    when lock_nowait or lock_timeout then
  --      raise_application_error(-20888, 'Some element in collection has been locked by another session:' || $$plsql_line);
  --    when others then
  --      raise;
  --  end;
  --exception when others then
  --  if (lv_refcur%isopen) then
  --    close lv_refcur;
  --  end if;
  --  raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  --end lock_all_pvt;

  ------------------------------------------------------------------
  ------------------------ Public Session --------------------------
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  -- EXISTS_ROW
  ------------------------------------------------------------------
  function exists_row(fr_id  in RecID)
    return boolean
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.EXISTS_ROW:';
  begin
    inspect_id_pvt(fr_id  => fr_id);
    return exists_row_pvt(fr_id => fr_id);
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end exists_row;
  ------------------------------------------------------------------
  function exists_row(fr_data  in RecData)
    return boolean
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.EXISTS_ROW:';
    lr_id           RecID;
  begin
    lr_id.r#wid := fr_data.r#wid;
    lr_id.id := fr_data.id;
    inspect_id_pvt(fr_id => lr_id);
    return exists_row_pvt(fr_id => lr_id);
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end exists_row;

  ------------------------------------------------------------------
  -- SELECT_ROW
  ------------------------------------------------------------------
  procedure select_row(fr_data  in out nocopy RecData,
                       fv_lock  in boolean default false)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.SELECT_ROW:';
    lr_id            RecID;
  begin
    lr_id.r#wid := fr_data.r#wid;
    lr_id.id := fr_data.id;
    inspect_id_pvt(fr_id => lr_id);
    if (fv_lock) then
      select_locking_pvt(fr_data => fr_data);
    else
      select_row_pvt(fr_data => fr_data);
    end if;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end select_row;

  ------------------------------------------------------------------
  -- INSERT_ROW
  ------------------------------------------------------------------
  procedure insert_row(fr_data  in out nocopy RecData)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.INSERT_ROW:';
  begin
    inspect_data_pvt(fr_data => fr_data);
    insert into r4v_customer
      ( -- column-list
        id,                                                                                     --001 number(38)
        first_name,                                                                             --002 varchar2(50 char)
        last_name,                                                                              --003 varchar2(50 char)
        email)                                                                                  --004 varchar2(150 char)
    values
      ( -- value-list
        fr_data.id,                                                                             --001 number(38)
        fr_data.first_name,                                                                     --002 varchar2(50 char)
        fr_data.last_name,                                                                      --003 varchar2(50 char)
        fr_data.email)                                                                          --004 varchar2(150 char)
    returning
        rowid,                                                                                  --000 urowid
        id,                                                                                     --001 number(38)
        first_name,                                                                             --002 varchar2(50 char)
        last_name,                                                                              --003 varchar2(50 char)
        email                                                                                   --004 varchar2(150 char)
    into
        fr_data.r#wid,                                                                          --000 urowid
        fr_data.id,                                                                             --001 number(38)
        fr_data.first_name,                                                                     --002 varchar2(50 char)
        fr_data.last_name,                                                                      --003 varchar2(50 char)
        fr_data.email;                                                                          --004 varchar2(150 char)
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end insert_row;

  ------------------------------------------------------------------
  -- INSERT_ALL
  ------------------------------------------------------------------
  procedure insert_all(ft_data    in out nocopy ArrData,
                       fv_rebind  in boolean default false)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.INSERT_ALL:';
    lt_id            ArrID;
    i                pls_integer;
  begin
    ------------
    << sanity >>
    ------------
    begin
      if (ft_data.count > gc_limit) then
        raise_application_error(-20888, 'ft_data.count() is limited to '
                                        || to_char(gc_limit) || ' elements:' || $$plsql_line);
      end if;
      i := ft_data.first;
      while (i is not null) loop
        pragma inline (inspect_data_pvt, 'YES');
        inspect_data_pvt(fr_data => ft_data(i));
        i := ft_data.next(i);
      end loop;
    exception when others then
      raise_application_error(-20777, '<< sanity >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end sanity;
    -----------------
    << forall_call >>
    -----------------
    begin
      forall i in indices of ft_data
      insert into r4v_customer
      ( -- column-list
        id,                                                                                     --001 number(38)
        first_name,                                                                             --002 varchar2(50 char)
        last_name,                                                                              --003 varchar2(50 char)
        email)                                                                                  --004 varchar2(150 char)
      values
      ( -- value-list
        ft_data(i).id,                                                                          --001 number(38)
        ft_data(i).first_name,                                                                  --002 varchar2(50 char)
        ft_data(i).last_name,                                                                   --003 varchar2(50 char)
        ft_data(i).email)                                                                       --004 varchar2(150 char)
      returning
        rowid,                                                                                  --000 urowid
        id                                                                                      --001 number(38)
      bulk collect into lt_id;
    exception when others then
      raise_application_error(-20777, '<< forall_call >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end forall_call;
    ------------
    << rebind >>
    ------------
    begin
      i := lt_id.first;
      while (i is not null) loop
        ft_data(i).r#wid := lt_id(i).r#wid;                                                     --000 urowid
        ft_data(i).id := lt_id(i).id;                                                           --001 number(38)
        if (fv_rebind) then
          pragma inline (select_row_pvt, 'YES');
          select_row_pvt(fr_data => ft_data(i));
        end if;
        i := lt_id.next(i);
      end loop;
    exception when others then
      raise_application_error(-20777, '<< rebind >>:'  || $$plsql_line || nl || dbms_utility.format_error_stack);
    end rebind;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end insert_all;

  ------------------------------------------------------------------
  -- LOCK_ROW
  ------------------------------------------------------------------
  procedure lock_row(fr_id  in RecID)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.LOCK_ROW:';
  begin
    inspect_id_pvt(fr_id  => fr_id);
    lock_row_pvt(fr_id => fr_id);
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end lock_row;
  ------------------------------------------------------------------
  procedure lock_row(fr_data  in RecData)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.LOCK_ROW:';
    lr_id            RecID;
  begin
    lr_id.r#wid := fr_data.r#wid;
    lr_id.id := fr_data.id;
    inspect_id_pvt(fr_id  => lr_id);
    lock_row_pvt(fr_id => lr_id);
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end lock_row;

  ------------------------------------------------------------------
  -- LOCK_ALL
  ------------------------------------------------------------------
  procedure lock_all(ft_id  in ArrID)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.LOCK_ALL:';
    i       pls_integer;
  begin
    i := ft_id.first;
    while (i is not null) loop
      pragma inline (lock_row, 'YES');
      lock_row(fr_id => ft_id(i));
      i := ft_id.next(i);
    end loop;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end lock_all;
  ------------------------------------------------------------------
  procedure lock_all(ft_data  in ArrData)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.LOCK_ALL:';
    i       pls_integer;
  begin
    i := ft_data.first;
    while (i is not null) loop
      pragma inline (lock_row, 'YES');
      lock_row(fr_data => ft_data(i));
      i := ft_data.next(i);
    end loop;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end lock_all;

  ------------------------------------------------------------------
  -- UPDATE_ROW
  ------------------------------------------------------------------
  procedure update_row(fr_data  in out nocopy RecData)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.UPDATE_ROW:';
  begin
    inspect_data_pvt(fr_data => fr_data);
    lock_row(fr_data => fr_data);
    update_row_pvt(fr_data => fr_data);
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end update_row;

  ------------------------------------------------------------------
  -- UPDATE_ALL
  ------------------------------------------------------------------
  procedure update_all(ft_data    in out nocopy ArrData,
                       fv_rebind  in boolean default false)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.UPDATE_ALL:';
    i                pls_integer;
  begin
    ------------
    << sanity >>
    ------------
    begin
      if (ft_data.count > gc_limit) then
        raise_application_error(-20888, 'ft_data.count() is limited to '
                                        || to_char(gc_limit) || ' elements:' || $$plsql_line);
      end if;
      i := ft_data.first;
      while (i is not null) loop
        pragma inline (inspect_data_pvt, 'YES');
        inspect_data_pvt(fr_data => ft_data(i));
        pragma inline (lock_row, 'YES');
        lock_row(fr_data => ft_data(i));
        i := ft_data.next(i);
      end loop;
    exception when others then
      raise_application_error(-20777, '<< sanity >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end sanity;
    -----------------
    << forall_call >>
    -----------------
    begin
      forall i in indices of ft_data
      update --+ rowid(a)
             r4v_customer    a
         set -- set-list
             a.first_name = ft_data(i).first_name,                                              --002 varchar2(50 char)
             a.last_name = ft_data(i).last_name,                                                --003 varchar2(50 char)
             a.email = ft_data(i).email                                                         --004 varchar2(150 char)
       where 1e1 = 1e1
         and a.rowid = ft_data(i).r#wid                                                         --000 urowid
         and a.id = ft_data(i).id;                                                              --001 number(38)
    exception when others then
      raise_application_error(-20777, '<< forall_call >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end forall_call;
    ------------
    << rebind >>
    ------------
    begin
      if (fv_rebind) then
        i := ft_data.first;
        while (i is not null) loop
          pragma inline (select_row_pvt, 'YES');
          select_row_pvt(fr_data => ft_data(i));
          i := ft_data.next(i);
        end loop;
      end if;
    exception when others then
      raise_application_error(-20777, '<< rebind >>:'  || $$plsql_line || nl || dbms_utility.format_error_stack);
    end rebind;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end update_all;

  ------------------------------------------------------------------
  -- DELETE_ROW
  ------------------------------------------------------------------
  procedure delete_row(fr_id  in RecID)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.DELETE_ROW:';
  begin
    lock_row(fr_id => fr_id);
    delete_row_pvt(fr_id => fr_id);
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end delete_row;
  ------------------------------------------------------------------
  procedure delete_row(fr_data  in RecData)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.DELETE_ROW:';
    lr_id            RecID;
  begin
    lr_id.r#wid := fr_data.r#wid;
    lr_id.id := fr_data.id;
    lock_row(fr_id => lr_id);
    delete_row_pvt(fr_id => lr_id);
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end delete_row;

  ------------------------------------------------------------------
  -- DELETE_ALL
  ------------------------------------------------------------------
  procedure delete_all(ft_id  in ArrID)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.DELETE_ALL:';
    i                pls_integer;
  begin
    ------------
    << sanity >>
    ------------
    begin
      if (ft_id.count > gc_limit) then
        raise_application_error(-20888, 'ft_id.count() is limited to '
                                        || to_char(gc_limit) || ' elements:' || $$plsql_line);
      end if;
      i := ft_id.first;
      while (i is not null) loop
        pragma inline (lock_row, 'YES');
        lock_row(fr_id => ft_id(i));
        i := ft_id.next(i);
      end loop;
    exception when others then
      raise_application_error(-20777, '<< sanity >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end sanity;
    -----------------
    << forall_call >>
    -----------------
    begin
      forall i in indices of ft_id
      delete --+ rowid(a)
        from r4v_customer    a
       where 1e1 = 1e1
         and a.rowid = ft_id(i).r#wid                                                           --000 urowid
         and a.id = ft_id(i).id;                                                                --001 number(38)
    exception when others then
      raise_application_error(-20777, '<< forall_call >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end forall_call;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end delete_all;
  ------------------------------------------------------------------
  procedure delete_all(ft_data  in ArrData)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.DELETE_ALL:';
    i                pls_integer;
  begin
    ------------
    << sanity >>
    ------------
    begin
      if (ft_data.count > gc_limit) then
        raise_application_error(-20888, 'ft_data.count() is limited to '
                                        || to_char(gc_limit) || ' elements:' || $$plsql_line);
      end if;
      i := ft_data.first;
      while (i is not null) loop
        pragma inline (lock_row, 'YES');
        lock_row(fr_data => ft_data(i));
        i := ft_data.next(i);
      end loop;
    exception when others then
      raise_application_error(-20777, '<< sanity >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end sanity;
    -----------------
    << forall_call >>
    -----------------
    begin
      forall i in indices of ft_data
      delete --+ rowid(a)
        from r4v_customer    a
       where 1e1 = 1e1
         and a.rowid = ft_data(i).r#wid                                                         --000 urowid
         and a.id = ft_data(i).id;                                                              --001 number(38)
    exception when others then
      raise_application_error(-20777, '<< forall_call >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end forall_call;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end delete_all;

  ------------------------------------------------------------------
  -- IS_NULL
  ------------------------------------------------------------------
  function is_null(fr_id  in RecID)
    return boolean
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.IS_NULL:';
  begin
    return true
           and fr_id.id    is null;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end is_null;
  ------------------------------------------------------------------
  function is_null(fr_data  in RecData)
    return boolean
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.IS_NULL:';
  begin
    return true
           and fr_data.id         is null
           and fr_data.first_name is null
           and fr_data.last_name  is null
           and fr_data.email      is null;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end is_null;

  ------------------------------------------------------------------
  -- IS_EQUAL
  ------------------------------------------------------------------
  function is_equal(fr_old  in RecID,
                    fr_new  in RecID)
    return boolean
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.IS_EQUAL:';
  begin
    return true
           -- id: integer
           and ((    fr_old.id    is null and     fr_new.id    is null) or 
                (not fr_old.id    is null and not fr_new.id    is null
                 and fr_old.id             =      fr_new.id   ));
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end is_equal;
  ------------------------------------------------------------------
  function is_equal(fr_old  in RecData,
                    fr_new  in RecData)
    return boolean
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.IS_EQUAL:';
  begin
    return true
           --001 id: integer
           and ((    fr_old.id         is null and     fr_new.id         is null) or 
                (not fr_old.id         is null and not fr_new.id         is null
                 and fr_old.id                  =      fr_new.id        ))
           --002 first_name: varchar2
           and ((    fr_old.first_name is null and     fr_new.first_name is null) or 
                (not fr_old.first_name is null and not fr_new.first_name is null
                 and fr_old.first_name          =      fr_new.first_name))
           --003 last_name: varchar2
           and ((    fr_old.last_name  is null and     fr_new.last_name  is null) or 
                (not fr_old.last_name  is null and not fr_new.last_name  is null
                 and fr_old.last_name           =      fr_new.last_name ))
           --004 email: varchar2
           and ((    fr_old.email      is null and     fr_new.email      is null) or 
                (not fr_old.email      is null and not fr_new.email      is null
                 and fr_old.email               =      fr_new.email     ))
           and true;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end is_equal;

  ------------------------------------------------------------------
  -- IS_SAME
  ------------------------------------------------------------------
  function is_same(fr_old  in RecID,
                   fr_new  in RecID)
    return boolean
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.IS_SAME:';
  begin
    pragma inline (is_equal, 'YES');
    return (     fr_old.r#wid is not null
             and fr_new.r#wid is not null
             and fr_old.r#wid = fr_new.r#wid
           ) and is_equal(fr_old => fr_old,
                          fr_new => fr_new);
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end is_same;
  ------------------------------------------------------------------
  function is_same(fr_old  in RecData,
                   fr_new  in RecData)
    return boolean
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.IS_SAME:';
  begin
    pragma inline (is_equal, 'YES');
    return (     fr_old.r#wid is not null
             and fr_new.r#wid is not null
             and fr_old.r#wid = fr_new.r#wid
           ) and is_equal(fr_old => fr_old,
                          fr_new => fr_new);
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end is_same;

  ------------------------------------------------------------------
  --------------------- Initialization Session ---------------------
  ------------------------------------------------------------------
begin
  $if $$plsql_optimize_level < 3 $then
    $error $$plsql_unit || ' must be compiled with PLSQL_OPTIMIZE_LEVEL=3' $end
  $end
  null;
exception when others then
  raise_application_error(-20777, $$plsql_unit || '<init>:'|| $$plsql_line || nl || dbms_utility.format_error_stack);
end r4v_customer_dml;
```
```sql
create or replace package body r4v_invoice_dml
is
  ------------------------------------------------------------------
  -- NKSG: PL/SQL Simple Generator
  ------------------------------------------------------------------
  --  (c) Copyright 2017 Geraldo Viana (r4vrya@gmail.com)
  --
  --  Licensed under the Apache License, Version 2.0 (the "License"):
  --  you may not use this file except in compliance with the License.
  --  You may obtain a copy of the License at
  --
  --      http://www.apache.org/licenses/LICENSE-2.0
  --
  --  Unless required by applicable law or agreed to in writing, software
  --  distributed under the License is distributed on an "AS IS" BASIS,
  --  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  --  See the License for the specific language governing permissions and
  --  limitations under the License.
  ------------------------------------------------------------------
  -- R4V_INVOICE_DML: R4V_INVOICE Simple CRUD API
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  ------------------------ Declare Session -------------------------
  ------------------------------------------------------------------
  -- Local constants
  nl       constant varchar2(3) := '
';

  -- Exceptions
  lock_timeout     exception;
  pragma exception_init(lock_timeout, -30006);    -- ORA-30006: resource busy; acquire with WAIT timeout expired
  lock_nowait      exception;
  pragma exception_init(lock_nowait, -54);        -- ORA-00054: resource busy and acquire with NOWAIT specified
  dml_error        exception;
  pragma exception_init(dml_error, -24381);       -- ORA-24381: error(s) in array DML

  -- Stateful Scalars/Containers
  --gt_urowid    urowid_list;

  ------------------------------------------------------------------
  ------------------------ Private Session -------------------------
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  -- BULK_EXCEPTION_PVT
  -- *** TODO ***
  ------------------------------------------------------------------
  --procedure bulk_exception_pvt(ft_error  in out nocopy plstring_list)
  --is
  --  lc__    constant varchar2(100) := $$plsql_unit || '.BULK_EXCEPTION_PVT:';
  --  j                pls_integer;
  --begin
  --  for i in 1 .. sql%bulk_exceptions.count loop
  --    j := sql%bulk_exceptions(i).error_index;
  --    ft_error(j) := sqlerrm(-sql%bulk_exceptions(i).error_code);
  --  end loop;
  --exception when others then
  --  raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  --end bulk_exception_pvt;

  ------------------------------------------------------------------
  -- INSPECT_DATA_PVT
  ------------------------------------------------------------------
  procedure inspect_data_pvt(fr_data  in out nocopy RecData)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.INSPECT_DATA_PVT:';
  begin
    if (fr_data.id is null) then
      raise_application_error(-20888, 'fr_data.id argument cannot be null:' || $$plsql_line);
    elsif (fr_data.invoice_amount is null) then
      raise_application_error(-20888, 'fr_data.invoice_amount argument cannot be null:' || $$plsql_line);
    elsif (fr_data.invoice_date is null) then
      raise_application_error(-20888, 'fr_data.invoice_date argument cannot be null:' || $$plsql_line);
    elsif (fr_data.pid_customer is null) then
      raise_application_error(-20888, 'fr_data.pid_customer argument cannot be null:' || $$plsql_line);
    end if;
    -- include defaults and sanities below this line...
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end inspect_data_pvt;

  ------------------------------------------------------------------
  -- INSPECT_ID_PVT
  ------------------------------------------------------------------
  procedure inspect_id_pvt(fr_id  in RecID)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.INSPECT_ID_PVT:';
  begin
    if (fr_id.r#wid is null) then
      raise_application_error(-20888, 'fr_id.r#wid argument cannot be null:' || $$plsql_line);
    elsif (fr_id.id is null) then
      raise_application_error(-20888, 'fr_id.id argument cannot be null:' || $$plsql_line);
    end if;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end inspect_id_pvt;

  ------------------------------------------------------------------
  -- SELECT_ROW_PVT
  ------------------------------------------------------------------
  procedure select_row_pvt(fr_data  in out nocopy RecData)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.SELECT_ROW_PVT:';
    lv_refcur        weak_refcursor;
  begin
    open lv_refcur for
    select --+ choose
           a.rowid,                                                                             --000 urowid
           a.id,                                                                                --001 number(38)
           a.pid_customer,                                                                      --002 number(38)
           a.invoice_date,                                                                      --003 date
           a.invoice_amount                                                                     --004 number(38,2)
      from r4v_invoice    a
     where 1e1 = 1e1
       and (fr_data.r#wid is null or a.rowid = fr_data.r#wid)                                   --000 urowid
       and a.id = fr_data.id;                                                                   --001 number(38)
    fetch lv_refcur into fr_data;
    close lv_refcur;
  exception when others then
    if (lv_refcur%isopen) then
      close lv_refcur;
    end if;
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end select_row_pvt;

  ------------------------------------------------------------------
  -- SELECT_LOCKING_PVT
  ------------------------------------------------------------------
  procedure select_locking_pvt(fr_data  in out nocopy RecData)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.SELECT_LOCKING_PVT:';
    lv_refcur        weak_refcursor;
  begin
    open lv_refcur for
    select --+ choose
           a.rowid,                                                                             --000 urowid
           a.id,                                                                                --001 number(38)
           a.pid_customer,                                                                      --002 number(38)
           a.invoice_date,                                                                      --003 date
           a.invoice_amount                                                                     --004 number(38,2)
      from r4v_invoice    a
     where 1e1 = 1e1
       and (fr_data.r#wid is null or a.rowid = fr_data.r#wid)                                   --000 urowid
       and a.id = fr_data.id                                                                    --001 number(38)
       for update wait 4;
    fetch lv_refcur into fr_data;
    close lv_refcur;
  exception when others then
    if (lv_refcur%isopen) then
      close lv_refcur;
    end if;
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end select_locking_pvt;

  ------------------------------------------------------------------
  -- EXISTS_ROW_PVT
  ------------------------------------------------------------------
  function exists_row_pvt(fr_id  in RecID)
    return boolean
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.EXISTS_ROW_PVT:';
    lv_refcur       weak_refcursor;
    lv_null         varchar2(1);
    lv_found        boolean := false;
  begin
    open lv_refcur for
    select --+ rowid(a)
           null
      from r4v_invoice    a
     where 1e1 = 1e1
       and (fr_id.r#wid is null or a.rowid = fr_id.r#wid)                                       --000 urowid
       and a.id = fr_id.id;                                                                     --001 number(38)
    fetch lv_refcur into lv_null;
    lv_found := lv_refcur%found;
    close lv_refcur;
    return lv_found;
  exception when others then
    if (lv_refcur%isopen) then
      close lv_refcur;
    end if;
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end exists_row_pvt;

  ------------------------------------------------------------------
  -- DELETE_ROW_PVT
  ------------------------------------------------------------------
  procedure delete_row_pvt(fr_id  in RecID)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.DELETE_ROW_PVT:';
  begin
    delete --+ rowid(a)
      from r4v_invoice    a
     where 1e1 = 1e1
       and a.rowid = fr_id.r#wid                                                                --000 urowid
       and a.id = fr_id.id;                                                                     --001 number(38)
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end delete_row_pvt;

  ------------------------------------------------------------------
  -- UPDATE_ROW_PVT
  ------------------------------------------------------------------
  procedure update_row_pvt(fr_data  in out nocopy RecData)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.UPDATE_ROW_PVT:';
  begin
    update --+ rowid(a)
           r4v_invoice    a
       set -- set-list
           a.pid_customer = fr_data.pid_customer,                                               --002 number(38)
           a.invoice_date = fr_data.invoice_date,                                               --003 date
           a.invoice_amount = fr_data.invoice_amount                                            --004 number(38,2)
     where 1e1 = 1e1
       and a.rowid = fr_data.r#wid                                                              --000 urowid
       and a.id = fr_data.id                                                                    --001 number(38)
    returning
           rowid,                                                                               --000 urowid
           id,                                                                                  --001 number(38)
           pid_customer,                                                                        --002 number(38)
           invoice_date,                                                                        --003 date
           invoice_amount                                                                       --004 number(38,2)
      into
           fr_data.r#wid,                                                                       --000 urowid
           fr_data.id,                                                                          --001 number(38)
           fr_data.pid_customer,                                                                --002 number(38)
           fr_data.invoice_date,                                                                --003 date
           fr_data.invoice_amount;                                                              --004 number(38,2)
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end update_row_pvt;

  ------------------------------------------------------------------
  -- LOCK_ROW_PVT
  ------------------------------------------------------------------
  procedure lock_row_pvt(fr_id  in RecID)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.LOCK_ROW_PVT:';
    lv_refcur        weak_refcursor;
  begin
    begin
      open lv_refcur for
      select --+ rowid(a)
             null
        from r4v_invoice    a
       where 1e1 = 1e1
         and a.rowid = fr_id.r#wid                                                              --000 urowid
         and a.id = fr_id.id                                                                    --001 number(38)
      for update wait 4;
      close lv_refcur;
    exception
      when lock_nowait or lock_timeout then
        raise_application_error(-20888, 'rowid[' || fr_id.r#wid
                                || '] locked by another session:' || $$plsql_line);
      when others then
        raise;
    end;
  exception when others then
    if (lv_refcur%isopen) then
      close lv_refcur;
    end if;
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end lock_row_pvt;

  ------------------------------------------------------------------
  -- LOCK_ALL_PVT
  -- *** TODO ***
  ------------------------------------------------------------------
  --procedure lock_all_pvt
  --is
  --  lc__    constant varchar2(100) := $$plsql_unit || '.LOCK_ALL_PVT:';
  --  lv_refcur        weak_refcursor;
  --begin
  --  begin
  --    open lv_refcur for
  --    select --+ rowid(a)
  --           null
  --      from r4v_invoice    a
  --     where 1e1 = 1e1
  --       and (a.rowid, a.id) in (select --+ dynamic_sampling(p, 10)
  --                                      chartorowid(p.map_item),
  --                                      to_number(p.map_value)
  --                                 from table(nksg_dmlapi.pipe_rowid)    p
  --                                where 1e1 = 1e1)
  --       for update wait 4;
  --    close lv_refcur;
  --  exception
  --    when lock_nowait or lock_timeout then
  --      raise_application_error(-20888, 'Some element in collection has been locked by another session:' || $$plsql_line);
  --    when others then
  --      raise;
  --  end;
  --exception when others then
  --  if (lv_refcur%isopen) then
  --    close lv_refcur;
  --  end if;
  --  raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  --end lock_all_pvt;

  ------------------------------------------------------------------
  ------------------------ Public Session --------------------------
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  -- EXISTS_ROW
  ------------------------------------------------------------------
  function exists_row(fr_id  in RecID)
    return boolean
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.EXISTS_ROW:';
  begin
    inspect_id_pvt(fr_id  => fr_id);
    return exists_row_pvt(fr_id => fr_id);
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end exists_row;
  ------------------------------------------------------------------
  function exists_row(fr_data  in RecData)
    return boolean
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.EXISTS_ROW:';
    lr_id           RecID;
  begin
    lr_id.r#wid := fr_data.r#wid;
    lr_id.id := fr_data.id;
    inspect_id_pvt(fr_id => lr_id);
    return exists_row_pvt(fr_id => lr_id);
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end exists_row;

  ------------------------------------------------------------------
  -- SELECT_ROW
  ------------------------------------------------------------------
  procedure select_row(fr_data  in out nocopy RecData,
                       fv_lock  in boolean default false)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.SELECT_ROW:';
    lr_id            RecID;
  begin
    lr_id.r#wid := fr_data.r#wid;
    lr_id.id := fr_data.id;
    inspect_id_pvt(fr_id => lr_id);
    if (fv_lock) then
      select_locking_pvt(fr_data => fr_data);
    else
      select_row_pvt(fr_data => fr_data);
    end if;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end select_row;

  ------------------------------------------------------------------
  -- INSERT_ROW
  ------------------------------------------------------------------
  procedure insert_row(fr_data  in out nocopy RecData)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.INSERT_ROW:';
  begin
    inspect_data_pvt(fr_data => fr_data);
    insert into r4v_invoice
      ( -- column-list
        id,                                                                                     --001 number(38)
        pid_customer,                                                                           --002 number(38)
        invoice_date,                                                                           --003 date
        invoice_amount)                                                                         --004 number(38,2)
    values
      ( -- value-list
        fr_data.id,                                                                             --001 number(38)
        fr_data.pid_customer,                                                                   --002 number(38)
        fr_data.invoice_date,                                                                   --003 date
        fr_data.invoice_amount)                                                                 --004 number(38,2)
    returning
        rowid,                                                                                  --000 urowid
        id,                                                                                     --001 number(38)
        pid_customer,                                                                           --002 number(38)
        invoice_date,                                                                           --003 date
        invoice_amount                                                                          --004 number(38,2)
    into
        fr_data.r#wid,                                                                          --000 urowid
        fr_data.id,                                                                             --001 number(38)
        fr_data.pid_customer,                                                                   --002 number(38)
        fr_data.invoice_date,                                                                   --003 date
        fr_data.invoice_amount;                                                                 --004 number(38,2)
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end insert_row;

  ------------------------------------------------------------------
  -- INSERT_ALL
  ------------------------------------------------------------------
  procedure insert_all(ft_data    in out nocopy ArrData,
                       fv_rebind  in boolean default false)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.INSERT_ALL:';
    lt_id            ArrID;
    i                pls_integer;
  begin
    ------------
    << sanity >>
    ------------
    begin
      if (ft_data.count > gc_limit) then
        raise_application_error(-20888, 'ft_data.count() is limited to '
                                        || to_char(gc_limit) || ' elements:' || $$plsql_line);
      end if;
      i := ft_data.first;
      while (i is not null) loop
        pragma inline (inspect_data_pvt, 'YES');
        inspect_data_pvt(fr_data => ft_data(i));
        i := ft_data.next(i);
      end loop;
    exception when others then
      raise_application_error(-20777, '<< sanity >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end sanity;
    -----------------
    << forall_call >>
    -----------------
    begin
      forall i in indices of ft_data
      insert into r4v_invoice
      ( -- column-list
        id,                                                                                     --001 number(38)
        pid_customer,                                                                           --002 number(38)
        invoice_date,                                                                           --003 date
        invoice_amount)                                                                         --004 number(38,2)
      values
      ( -- value-list
        ft_data(i).id,                                                                          --001 number(38)
        ft_data(i).pid_customer,                                                                --002 number(38)
        ft_data(i).invoice_date,                                                                --003 date
        ft_data(i).invoice_amount)                                                              --004 number(38,2)
      returning
        rowid,                                                                                  --000 urowid
        id                                                                                      --001 number(38)
      bulk collect into lt_id;
    exception when others then
      raise_application_error(-20777, '<< forall_call >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end forall_call;
    ------------
    << rebind >>
    ------------
    begin
      i := lt_id.first;
      while (i is not null) loop
        ft_data(i).r#wid := lt_id(i).r#wid;                                                     --000 urowid
        ft_data(i).id := lt_id(i).id;                                                           --001 number(38)
        if (fv_rebind) then
          pragma inline (select_row_pvt, 'YES');
          select_row_pvt(fr_data => ft_data(i));
        end if;
        i := lt_id.next(i);
      end loop;
    exception when others then
      raise_application_error(-20777, '<< rebind >>:'  || $$plsql_line || nl || dbms_utility.format_error_stack);
    end rebind;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end insert_all;

  ------------------------------------------------------------------
  -- LOCK_ROW
  ------------------------------------------------------------------
  procedure lock_row(fr_id  in RecID)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.LOCK_ROW:';
  begin
    inspect_id_pvt(fr_id  => fr_id);
    lock_row_pvt(fr_id => fr_id);
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end lock_row;
  ------------------------------------------------------------------
  procedure lock_row(fr_data  in RecData)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.LOCK_ROW:';
    lr_id            RecID;
  begin
    lr_id.r#wid := fr_data.r#wid;
    lr_id.id := fr_data.id;
    inspect_id_pvt(fr_id  => lr_id);
    lock_row_pvt(fr_id => lr_id);
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end lock_row;

  ------------------------------------------------------------------
  -- LOCK_ALL
  ------------------------------------------------------------------
  procedure lock_all(ft_id  in ArrID)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.LOCK_ALL:';
    i       pls_integer;
  begin
    i := ft_id.first;
    while (i is not null) loop
      pragma inline (lock_row, 'YES');
      lock_row(fr_id => ft_id(i));
      i := ft_id.next(i);
    end loop;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end lock_all;
  ------------------------------------------------------------------
  procedure lock_all(ft_data  in ArrData)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.LOCK_ALL:';
    i       pls_integer;
  begin
    i := ft_data.first;
    while (i is not null) loop
      pragma inline (lock_row, 'YES');
      lock_row(fr_data => ft_data(i));
      i := ft_data.next(i);
    end loop;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end lock_all;

  ------------------------------------------------------------------
  -- UPDATE_ROW
  ------------------------------------------------------------------
  procedure update_row(fr_data  in out nocopy RecData)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.UPDATE_ROW:';
  begin
    inspect_data_pvt(fr_data => fr_data);
    lock_row(fr_data => fr_data);
    update_row_pvt(fr_data => fr_data);
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end update_row;

  ------------------------------------------------------------------
  -- UPDATE_ALL
  ------------------------------------------------------------------
  procedure update_all(ft_data    in out nocopy ArrData,
                       fv_rebind  in boolean default false)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.UPDATE_ALL:';
    i                pls_integer;
  begin
    ------------
    << sanity >>
    ------------
    begin
      if (ft_data.count > gc_limit) then
        raise_application_error(-20888, 'ft_data.count() is limited to '
                                        || to_char(gc_limit) || ' elements:' || $$plsql_line);
      end if;
      i := ft_data.first;
      while (i is not null) loop
        pragma inline (inspect_data_pvt, 'YES');
        inspect_data_pvt(fr_data => ft_data(i));
        pragma inline (lock_row, 'YES');
        lock_row(fr_data => ft_data(i));
        i := ft_data.next(i);
      end loop;
    exception when others then
      raise_application_error(-20777, '<< sanity >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end sanity;
    -----------------
    << forall_call >>
    -----------------
    begin
      forall i in indices of ft_data
      update --+ rowid(a)
             r4v_invoice    a
         set -- set-list
             a.pid_customer = ft_data(i).pid_customer,                                          --002 number(38)
             a.invoice_date = ft_data(i).invoice_date,                                          --003 date
             a.invoice_amount = ft_data(i).invoice_amount                                       --004 number(38,2)
       where 1e1 = 1e1
         and a.rowid = ft_data(i).r#wid                                                         --000 urowid
         and a.id = ft_data(i).id;                                                              --001 number(38)
    exception when others then
      raise_application_error(-20777, '<< forall_call >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end forall_call;
    ------------
    << rebind >>
    ------------
    begin
      if (fv_rebind) then
        i := ft_data.first;
        while (i is not null) loop
          pragma inline (select_row_pvt, 'YES');
          select_row_pvt(fr_data => ft_data(i));
          i := ft_data.next(i);
        end loop;
      end if;
    exception when others then
      raise_application_error(-20777, '<< rebind >>:'  || $$plsql_line || nl || dbms_utility.format_error_stack);
    end rebind;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end update_all;

  ------------------------------------------------------------------
  -- DELETE_ROW
  ------------------------------------------------------------------
  procedure delete_row(fr_id  in RecID)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.DELETE_ROW:';
  begin
    lock_row(fr_id => fr_id);
    delete_row_pvt(fr_id => fr_id);
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end delete_row;
  ------------------------------------------------------------------
  procedure delete_row(fr_data  in RecData)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.DELETE_ROW:';
    lr_id            RecID;
  begin
    lr_id.r#wid := fr_data.r#wid;
    lr_id.id := fr_data.id;
    lock_row(fr_id => lr_id);
    delete_row_pvt(fr_id => lr_id);
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end delete_row;

  ------------------------------------------------------------------
  -- DELETE_ALL
  ------------------------------------------------------------------
  procedure delete_all(ft_id  in ArrID)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.DELETE_ALL:';
    i                pls_integer;
  begin
    ------------
    << sanity >>
    ------------
    begin
      if (ft_id.count > gc_limit) then
        raise_application_error(-20888, 'ft_id.count() is limited to '
                                        || to_char(gc_limit) || ' elements:' || $$plsql_line);
      end if;
      i := ft_id.first;
      while (i is not null) loop
        pragma inline (lock_row, 'YES');
        lock_row(fr_id => ft_id(i));
        i := ft_id.next(i);
      end loop;
    exception when others then
      raise_application_error(-20777, '<< sanity >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end sanity;
    -----------------
    << forall_call >>
    -----------------
    begin
      forall i in indices of ft_id
      delete --+ rowid(a)
        from r4v_invoice    a
       where 1e1 = 1e1
         and a.rowid = ft_id(i).r#wid                                                           --000 urowid
         and a.id = ft_id(i).id;                                                                --001 number(38)
    exception when others then
      raise_application_error(-20777, '<< forall_call >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end forall_call;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end delete_all;
  ------------------------------------------------------------------
  procedure delete_all(ft_data  in ArrData)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.DELETE_ALL:';
    i                pls_integer;
  begin
    ------------
    << sanity >>
    ------------
    begin
      if (ft_data.count > gc_limit) then
        raise_application_error(-20888, 'ft_data.count() is limited to '
                                        || to_char(gc_limit) || ' elements:' || $$plsql_line);
      end if;
      i := ft_data.first;
      while (i is not null) loop
        pragma inline (lock_row, 'YES');
        lock_row(fr_data => ft_data(i));
        i := ft_data.next(i);
      end loop;
    exception when others then
      raise_application_error(-20777, '<< sanity >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end sanity;
    -----------------
    << forall_call >>
    -----------------
    begin
      forall i in indices of ft_data
      delete --+ rowid(a)
        from r4v_invoice    a
       where 1e1 = 1e1
         and a.rowid = ft_data(i).r#wid                                                         --000 urowid
         and a.id = ft_data(i).id;                                                              --001 number(38)
    exception when others then
      raise_application_error(-20777, '<< forall_call >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end forall_call;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end delete_all;

  ------------------------------------------------------------------
  -- IS_NULL
  ------------------------------------------------------------------
  function is_null(fr_id  in RecID)
    return boolean
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.IS_NULL:';
  begin
    return true
           and fr_id.id    is null;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end is_null;
  ------------------------------------------------------------------
  function is_null(fr_data  in RecData)
    return boolean
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.IS_NULL:';
  begin
    return true
           and fr_data.id             is null
           and fr_data.pid_customer   is null
           and fr_data.invoice_date   is null
           and fr_data.invoice_amount is null;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end is_null;

  ------------------------------------------------------------------
  -- IS_EQUAL
  ------------------------------------------------------------------
  function is_equal(fr_old  in RecID,
                    fr_new  in RecID)
    return boolean
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.IS_EQUAL:';
  begin
    return true
           -- id: integer
           and ((    fr_old.id    is null and     fr_new.id    is null) or 
                (not fr_old.id    is null and not fr_new.id    is null
                 and fr_old.id             =      fr_new.id   ));
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end is_equal;
  ------------------------------------------------------------------
  function is_equal(fr_old  in RecData,
                    fr_new  in RecData)
    return boolean
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.IS_EQUAL:';
  begin
    return true
           --001 id: integer
           and ((    fr_old.id             is null and     fr_new.id             is null) or 
                (not fr_old.id             is null and not fr_new.id             is null
                 and fr_old.id                      =      fr_new.id            ))
           --002 pid_customer: integer
           and ((    fr_old.pid_customer   is null and     fr_new.pid_customer   is null) or 
                (not fr_old.pid_customer   is null and not fr_new.pid_customer   is null
                 and fr_old.pid_customer            =      fr_new.pid_customer  ))
           --003 invoice_date: date
           and ((    fr_old.invoice_date   is null and     fr_new.invoice_date   is null) or 
                (not fr_old.invoice_date   is null and not fr_new.invoice_date   is null
                 and fr_old.invoice_date            =      fr_new.invoice_date  ))
           --004 invoice_amount: number
           and ((    fr_old.invoice_amount is null and     fr_new.invoice_amount is null) or 
                (not fr_old.invoice_amount is null and not fr_new.invoice_amount is null
                 and fr_old.invoice_amount          =      fr_new.invoice_amount))
           and true;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end is_equal;

  ------------------------------------------------------------------
  -- IS_SAME
  ------------------------------------------------------------------
  function is_same(fr_old  in RecID,
                   fr_new  in RecID)
    return boolean
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.IS_SAME:';
  begin
    pragma inline (is_equal, 'YES');
    return (     fr_old.r#wid is not null
             and fr_new.r#wid is not null
             and fr_old.r#wid = fr_new.r#wid
           ) and is_equal(fr_old => fr_old,
                          fr_new => fr_new);
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end is_same;
  ------------------------------------------------------------------
  function is_same(fr_old  in RecData,
                   fr_new  in RecData)
    return boolean
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.IS_SAME:';
  begin
    pragma inline (is_equal, 'YES');
    return (     fr_old.r#wid is not null
             and fr_new.r#wid is not null
             and fr_old.r#wid = fr_new.r#wid
           ) and is_equal(fr_old => fr_old,
                          fr_new => fr_new);
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end is_same;

  ------------------------------------------------------------------
  --------------------- Initialization Session ---------------------
  ------------------------------------------------------------------
begin
  $if $$plsql_optimize_level < 3 $then
    $error $$plsql_unit || ' must be compiled with PLSQL_OPTIMIZE_LEVEL=3' $end
  $end
  null;
exception when others then
  raise_application_error(-20777, $$plsql_unit || '<init>:'|| $$plsql_line || nl || dbms_utility.format_error_stack);
end r4v_invoice_dml;
```
