create or replace package body nksg_dmlapi
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
  -- NKSG_DMLAPI: Generates Simple CRUD API
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  ------------------------ Declare Session -------------------------
  ------------------------------------------------------------------
  -- Local constants
  s#    constant varchar2(1) := chr(5);  -- ASCII 5: ENQ(Enquiry)
  nl    constant varchar2(1) := '
';

  -- Hardcoded ROWID element identifier: 'R#WID', 'r#wid'

  -- Lookup constants
  gc_owner          constant varchar2(30) := coalesce(sys_context('USERENV', 'SESSION_USER'), user);
  gc_rowid          constant varchar2(35) := 'ROWID';
  gc_urowid         constant varchar2(35) := 'UROWID';
  gc_float          constant varchar2(35) := 'FLOAT';
  gc_binary_float   constant varchar2(35) := 'BINARY_FLOAT';
  gc_binary_double  constant varchar2(35) := 'BINARY_DOUBLE';
  gc_number         constant varchar2(35) := 'NUMBER';
  gc_date           constant varchar2(35) := 'DATE';
  gc_timestamp      constant varchar2(35) := 'TIMESTAMP(_)';                      -- TIMESTAMP(0..9)
  gc_tstampwtz      constant varchar2(35) := 'TIMESTAMP(_) WITH TIME ZONE';       -- TIMESTAMP(0..9)
  gc_tstampwltz     constant varchar2(35) := 'TIMESTAMP(_) WITH LOCAL TIME ZONE'; -- TIMESTAMP(0..9)
  gc_intervalytm    constant varchar2(35) := 'INTERVAL YEAR(_) TO MONTH';         -- YEAR(0..9)
  gc_intervaldts    constant varchar2(35) := 'INTERVAL DAY(_) TO SECOND(_)';      -- DAY(0..9), SECOND(0..9)
  gc_char           constant varchar2(35) := 'CHAR';
  gc_nchar          constant varchar2(35) := 'NCHAR';
  gc_varchar        constant varchar2(35) := 'VARCHAR';
  gc_varchar2       constant varchar2(35) := 'VARCHAR2';
  gc_nvarchar2      constant varchar2(35) := 'NVARCHAR2';
  gc_clob           constant varchar2(35) := 'CLOB';
  gc_nclob          constant varchar2(35) := 'NCLOB';
  gc_blob           constant varchar2(35) := 'BLOB';
  gc_bfile          constant varchar2(35) := 'BFILE';
  gc_raw            constant varchar2(35) := 'RAW';
  gc_long           constant varchar2(35) := 'LONG';
  gc_long_raw       constant varchar2(35) := 'LONG RAW';
  gc_xmltype        constant varchar2(35) := 'XMLTYPE';

  -- plsql
  gc_plstringub     constant pls_integer := 32767; -- PLSQL varchar2 upper bound
  gc_plrawub        constant pls_integer := 32767; -- PLSQL raw upper bound
  gc_sqlstringub    constant pls_integer := 4000;  -- SQL varchar2 upper bound
  gc_sqlrawub       constant pls_integer := 2000;  -- SQL raw upper bound
  subtype plstring  is varchar2(32767); -- keep same as gc_plstringub
  subtype plraw     is raw(32767);      -- keep same as gc_plrawub
  subtype sqlstring is varchar2(4000);  -- keep same as gc_sqlstringub
  subtype sqlraw    is raw(2000);       -- keep same as gc_sqlrawub

  -- Local types
  type weak_refcursor is ref cursor;
  type plstring_list  is table of plstring index by pls_integer;

  -- Generator types
  type RecCheck is record(column_name  varchar2(30),
                          check_stmt   plstring);
  type ArrCheck is table of RecCheck index by pls_integer;

  type RecMetaData is record(column_id       number,
                             column_name     varchar2(30),
                             data_type       varchar2(255),
                             char_used       varchar2(65),
                             data_length     number,
                             char_length     number,
                             data_precision  number,
                             data_scale      number,
                             nullable        varchar2(1));
  type ArrMetaData is table of RecMetaData index by pls_integer;

  type RecNamespace is record(table_name   varchar2(30),
                              api_name     varchar2(30));

  type RecElement is record(column_id      number,
                            column_name    varchar2(30),
                            argument_type  varchar2(255),
                            record_type    varchar2(255),
                            flag           varchar2(255),
                            comparable     boolean,
                            returnable     boolean);
  type ArrElement is table of RecElement index by pls_integer;

  type RecBundle is record(namespace      RecNamespace,
                           full_element   ArrElement,    -- 'r#wid' + 'all columns'
                           pk_element     ArrElement,    -- 'r#wid' + 'primary keys'
                           diff_element   ArrElement,    -- 'all columns' minus 'primary keys'
                           ret_element    ArrElement,    -- returnables
                           check_list     plstring_list);

  -- Namespace lookup
  gc_namespace_stmt    constant plstring := '/*~ ' || $$plsql_unit || ':' || $$plsql_line || ' */' ||
  q'[
  select --+ choose
         a.table_name                                    "TABLE_NAME",
         case
           when a.table_name like '%\_ALL' escape '\'
           then substr(a.table_name, 1,
                length(a.table_name)-4) || '_DML'
         else
           substr(a.table_name, 1, 26) || '_DML'
         end                                             "API_NAME"
    from
         user_tables    a
   where 1e1 = 1e1
     and a.table_name = :table_name
   order by a.table_name
  ]';

  -- Table columns
  gc_tabcol_stmt    constant plstring := '/*~ ' || $$plsql_unit || ':' || $$plsql_line || ' */' ||
  q'[
  select --+ choose
         il.column_id                               "COLUMN_ID",       -- number
         il.column_name                             "COLUMN_NAME",     -- varchar2(30)
         il.data_type                               "DATA_TYPE",       -- varchar2(255)
         il.char_used                               "CHAR_USED",       -- varchar2(65)
         il.data_length                             "DATA_LENGTH",     -- number
         il.char_length                             "CHAR_LENGTH",     -- number
         il.data_precision                          "DATA_PRECISION",  -- number
         il.data_scale                              "DATA_SCALE",      -- number
         il.nullable                                "NULLABLE"         -- varchar2(1)
    from (-- in-line view
          select --+ choose
                 cast('0'      as number)           "COLUMN_ID",       -- number
                 cast('R#WID'  as varchar2(30))     "COLUMN_NAME",     -- varchar2(30)
                 cast('UROWID' as varchar2(256))    "DATA_TYPE",       -- varchar2(255)
                 cast(null     as varchar2(65))     "CHAR_USED",       -- varchar2(65)
                 cast(null     as number)           "DATA_LENGTH",     -- number
                 cast(null     as number)           "CHAR_LENGTH",     -- number
                 cast(null     as number)           "DATA_PRECISION",  -- number
                 cast(null     as number)           "DATA_SCALE",      -- number
                 cast(null     as varchar2(1))      "NULLABLE"         -- varchar2(1)
            from dual
           where 1e1 = 1e1
          union all
          select --+ choose
                 a.column_id                        "COLUMN_ID",       -- number
                 a.column_name                      "COLUMN_NAME",     -- varchar2(30)
                 a.data_type                        "DATA_TYPE",       -- varchar2(255)
                 case a.char_used
                   when 'B' then 'BYTE'
                   when 'C' then 'CHAR'
                 else
                   a.char_used
                 end                                "CHAR_USED",       -- varchar2(65)
                 a.data_length                      "DATA_LENGTH",     -- number
                 a.char_length                      "CHAR_LENGTH",     -- number
                 a.data_precision                   "DATA_PRECISION",  -- number
                 a.data_scale                       "DATA_SCALE",      -- number
                 a.nullable                         "NULLABLE"         -- varchar2(1)
            from
                 user_tab_columns    a
           where 1e1 = 1e1
             and a.table_name = :table_name
           order by 1
         ) il
   where 1e1 = 1e1
  ]';

  -- Primary key columns
  gc_tabkey_stmt    constant plstring := '/*~ ' || $$plsql_unit || ':' || $$plsql_line || ' */' ||
  q'[
  select --+ choose
         il.column_name                             "COLUMN_NAME"
    from (-- in-line view
          select --+ CHOOSE
                 cast('0'      as number)           "POSITION",
                 cast('R#WID'  as varchar(30))      "COLUMN_NAME"
            from dual
           where 1e1 = 1e1
          union all
          select --+ choose
                 aa.position                        "POSITION",
                 aa.column_name                     "COLUMN_NAME"
            from
                   user_cons_columns     aa,
                 user_constraints      a
           where 1e1 = 1e1
              -- user_constraints[access/filter]
             and a.owner = :owner
             and a.table_name = :table_name
             and a.constraint_type = 'P'                -- Primary Key
              -- user_constraints --< user_cons_columns
             and a.owner = aa.owner
             and a.constraint_name = aa.constraint_name
           order by 1
          ) il
   where 1e1 =1e1
  ]';

  -- Check constraints
  gc_checkcon_stmt    constant plstring := '/*~ ' || $$plsql_unit || ':' || $$plsql_line || ' */' ||
  q'[
  select --+ choose
         aa.column_name,
         a.search_condition
    from
           user_cons_columns          aa,
         user_constraints           a
   where 1e1 = 1e1
      -- user_constraints[access/filter]
     and a.owner = :owner
     and a.table_name = :table_name
     and a.constraint_type = 'C'
      -- user_constraints --< user_cons_columns
     and a.owner = aa.owner
     and a.constraint_name = aa.constraint_name
    order by aa.column_name
  ]';

  -- stateful scalars/containers
  gv_plid  pls_integer; -- NKSG_TEMPCLOB Payload ID

  ------------------------------------------------------------------
  ------------------------ Private Session -------------------------
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  -- RETURNABLE_TYPE_PVT: Assert types 'returnability'
  ------------------------------------------------------------------
  function returnable_type_pvt(fr_metadata  in RecMetaData)
    return boolean
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.RETURNABLE_TYPE_PVT:';
  begin
    return false
        or fr_metadata.data_type = gc_float
        or fr_metadata.data_type = gc_number
        or fr_metadata.data_type = gc_raw
        or fr_metadata.data_type = gc_rowid
        or fr_metadata.data_type = gc_urowid
        or fr_metadata.data_type = gc_char
        or fr_metadata.data_type = gc_nchar
        or fr_metadata.data_type = gc_varchar
        or fr_metadata.data_type = gc_varchar2
        or fr_metadata.data_type = gc_nvarchar2
        or fr_metadata.data_type = gc_date
        or fr_metadata.data_type = gc_clob
        or fr_metadata.data_type = gc_nclob
        or fr_metadata.data_type = gc_blob
        or fr_metadata.data_type = gc_bfile
        or fr_metadata.data_type = gc_binary_float
        or fr_metadata.data_type = gc_binary_double
        or instrb(fr_metadata.data_type, 'TIMESTAMP') > 0
        or instrb(fr_metadata.data_type, 'INTERVAL') > 0;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end returnable_type_pvt;

  ------------------------------------------------------------------
  -- COMPARABLE_TYPE_PVT: Assert types comparability
  ------------------------------------------------------------------
  function comparable_type_pvt(fr_metadata  in RecMetaData)
    return boolean
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.COMPARABLE_TYPE_PVT:';
  begin
    return false
        or fr_metadata.data_type = gc_float
        or fr_metadata.data_type = gc_number
        or fr_metadata.data_type = gc_raw
        or fr_metadata.data_type = gc_rowid
        or fr_metadata.data_type = gc_urowid
        or fr_metadata.data_type = gc_char
        or fr_metadata.data_type = gc_nchar
        or fr_metadata.data_type = gc_varchar
        or fr_metadata.data_type = gc_varchar2
        or fr_metadata.data_type = gc_nvarchar2
        or fr_metadata.data_type = gc_date
        or fr_metadata.data_type = gc_clob
        or fr_metadata.data_type = gc_nclob
        or fr_metadata.data_type = gc_blob
        or fr_metadata.data_type = gc_bfile
        or fr_metadata.data_type = gc_binary_float
        or fr_metadata.data_type = gc_binary_double
        or instrb(fr_metadata.data_type, 'TIMESTAMP') > 0
        or instrb(fr_metadata.data_type, 'INTERVAL') > 0;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end comparable_type_pvt;

  ------------------------------------------------------------------
  -- ARGUMENT_TYPE_PVT: Subprogram argument types
  ------------------------------------------------------------------
  function argument_type_pvt(fr_metadata  in RecMetaData)
    return varchar2
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.ARGUMENT_TYPE_PVT:';
    lv_result       plstring;
  begin
    if (fr_metadata.data_type = gc_number) then
      if (fr_metadata.data_scale > 0) then
        lv_result := 'number';
      else
        lv_result := 'integer';
      end if;
    elsif (fr_metadata.data_type = gc_char) then
      lv_result := 'char';
    elsif (fr_metadata.data_type = gc_nchar) then
      lv_result := 'nchar';
    elsif (fr_metadata.data_type = gc_raw) then
      lv_result := 'raw';
    elsif (fr_metadata.data_type = gc_varchar2) then
      lv_result := 'varchar2';
    elsif (fr_metadata.data_type = gc_nvarchar2) then
      lv_result := 'nvarchar2';
    elsif (instrb(fr_metadata.data_type, 'TIMESTAMP') > 0) then
      lv_result := lower(regexp_replace(fr_metadata.data_type, '(\()|(\))|[[:digit:]]'));
    elsif (instrb(fr_metadata.data_type, 'INTERVAL') > 0) then
      lv_result := lower(regexp_replace(fr_metadata.data_type, '(\()|(\))|[[:digit:]]'));
    else
      lv_result := lower(fr_metadata.data_type);
    end if;
    return lv_result;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end argument_type_pvt;

  ------------------------------------------------------------------
  -- RECORD_TYPE_PVT: Record element types
  ------------------------------------------------------------------
  function record_type_pvt(fr_metadata  in RecMetaData)
    return varchar2
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.RECORD_TYPE_PVT:';
    lv_semantic     plstring := ')';
    lv_result       plstring;
  begin
    if (fr_metadata.char_used is not null) then
      lv_semantic := lower(' ' || fr_metadata.char_used || ')');
    end if;
    if (fr_metadata.data_type = gc_number) then
      if (fr_metadata.data_precision is null and fr_metadata.data_scale is null) then
      lv_result := 'number';
      elsif (fr_metadata.data_precision is null and nvl(fr_metadata.data_scale,0) > 0) then
      lv_result := 'number(38,' || to_char(fr_metadata.data_scale) || ')';
      elsif (fr_metadata.data_precision is not null and nvl(fr_metadata.data_scale,0) = 0) then
      lv_result := 'number(' || to_char(fr_metadata.data_precision) || ')';
      elsif (fr_metadata.data_precision is not null and fr_metadata.data_scale is not null) then
      lv_result := 'number(' || to_char(fr_metadata.data_precision) || ','
                             || to_char(fr_metadata.data_scale)     || ')';
      end if;
    elsif (fr_metadata.data_type = gc_char) then
      lv_result := 'char(' || to_char(fr_metadata.char_length) || lv_semantic;
    elsif (fr_metadata.data_type = gc_nchar) then
      lv_result := 'nchar(' || to_char(fr_metadata.char_length) || lv_semantic;
    elsif (fr_metadata.data_type = gc_raw) then
      lv_result := 'raw(' || to_char(fr_metadata.data_length) || ')';
    elsif (fr_metadata.data_type = gc_varchar2) then
      lv_result := 'varchar2(' || to_char(fr_metadata.char_length) || lv_semantic;
    elsif (fr_metadata.data_type = gc_nvarchar2) then
      lv_result := 'nvarchar2(' || to_char(fr_metadata.char_length) || lv_semantic;
    elsif (instr(fr_metadata.data_type, 'TIMESTAMP') > 0) then
      lv_result := lower(regexp_replace(fr_metadata.data_type, '(\()|(\))|[[:digit:]]'));
    elsif (instr(fr_metadata.data_type, 'INTERVAL') > 0) then
      lv_result := lower(regexp_replace(fr_metadata.data_type, '(\()|(\))|[[:digit:]]'));
    else
      lv_result := lower(fr_metadata.data_type);
    end if;
    return lv_result;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end record_type_pvt;

  ------------------------------------------------------------------
  -- FETCH_NAMESPACE_PVT
  ------------------------------------------------------------------
  procedure fetch_namespace_pvt(fv_table      in varchar2,
                                fr_namespace  in out nocopy RecNamespace)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.FETCH_NAMESPACE_PVT:';
    lv_refcur        weak_refcursor;
  begin
    open lv_refcur for gc_namespace_stmt using fv_table;
    fetch lv_refcur into fr_namespace;
    close lv_refcur;
  exception when others then
    if (lv_refcur%isopen) then
      close lv_refcur;
    end if;
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end fetch_namespace_pvt;

  ------------------------------------------------------------------
  -- BULK_TABKEY_PVT
  ------------------------------------------------------------------
  procedure bulk_tabkey_pvt(fv_table      in varchar2,
                            ft_indexlist  in out nocopy plstring_list)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.BULK_TABKEY_PVT:';
  begin
    execute immediate gc_tabkey_stmt bulk collect into ft_indexlist
      using gc_owner, fv_table;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end bulk_tabkey_pvt;

  ------------------------------------------------------------------
  -- BULK_TABCOL_PVT
  ------------------------------------------------------------------
  procedure bulk_tabcol_pvt(fv_table     in varchar2,
                            ft_metadata  in out nocopy ArrMetaData)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.BULK_TABCOL_PVT:';
  begin
    execute immediate gc_tabcol_stmt bulk collect into ft_metadata
      using fv_table;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end bulk_tabcol_pvt;

  ------------------------------------------------------------------
  -- BULK_CHECKCON_PVT
  ------------------------------------------------------------------
  procedure bulk_checkcon_pvt(fv_table  in varchar2,
                              ft_check  in out nocopy ArrCheck)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.BULK_CHECKCON_PVT:';
  begin
    execute immediate gc_checkcon_stmt bulk collect into ft_check
      using gc_owner, fv_table;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end bulk_checkcon_pvt;

  ------------------------------------------------------------------
  -- PARSE_CHECKCON_PVT
  ------------------------------------------------------------------
  procedure parse_checkcon_pvt(fv_table       in varchar2,
                               ft_check_list  in out nocopy plstring_list)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.PARSE_CHECKCON_PVT:';
    lt_check         ArrCheck;
    lv_buffer        plstring;
    lv_consexpr      plstring;
    lv_conscol       plstring;
    lv_conslist      Plstring;
    i                pls_integer;
    j                pls_integer;
  begin
    bulk_checkcon_pvt(fv_table => fv_table,
                      ft_check => lt_check);
    i := lt_check.first;
    while (i is not null) loop
      lv_buffer := lt_check(i).check_stmt;
      lv_buffer := translate(lv_buffer, ' ' || chr(9) || chr(10) || chr(13), ' ');
      lv_buffer := regexp_replace(lv_buffer, '^(\s)+|(\s)+$|(\s){2,}', '\3');
      if (instrb(upper(lv_buffer), 'IS NOT NULL') != 0) then
        lv_conscol := replace(lower(substr(lv_buffer, 1, instr(lv_buffer, ' ')-1)), '"');
        lv_buffer := '(fr_data.' || lv_conscol || ' is null) then' || nl ||
                     '      raise_application_error(-20888, ''fr_data.' || lower(lv_conscol)
                     || ' argument cannot be null:'' || $$plsql_line);' || nl;
        ft_check_list(ft_check_list.count+1) := lv_buffer;
        j := i;
      else
        j := null;
      end if;
      i := lt_check.next(i);
      if (j is not null) then
        lt_check.delete(j);
      end if;
    end loop;
    i := lt_check.first;
    while (i is not null) loop
      lv_consexpr := replace(upper(lt_check(i).check_stmt), '"');
      lv_consexpr := regexp_replace(lv_consexpr, '^(\s)+|(\s)+$|(\s){2,}', '\3');
      lv_consexpr := replace(lv_consexpr, upper(lt_check(i).column_name),
                                          'fr_data.' || lt_check(i).column_name);
      lv_consexpr := replace(lv_consexpr, 'fr_data.' || upper(lt_check(i).column_name),
                                          'fr_data.' || lower(lt_check(i).column_name));
      lv_buffer := '(not (' || lv_consexpr || ')) then' || nl ||
                      '      raise_application_error(-20888, ''Check failed: [' || replace(lv_consexpr, '''', '''''')
                      || ']:'' || $$plsql_line);' || nl;
      ft_check_list(ft_check_list.count+1) := lv_buffer;
      i := lt_check.next(i);
    end loop;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end parse_checkcon_pvt;

  ------------------------------------------------------------------
  -- FILL_METADATA_PVT
  ------------------------------------------------------------------
  procedure fill_metadata_pvt(fv_table   in varchar2,
                              fr_bundle  in out nocopy RecBundle)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.FILL_METADATA_PVT:';
    lt_metadata      ArrMetaData;
    lt_tabkey        plstring_list;
    lt_full_element  ArrElement;
    lt_pk_element    ArrElement;
    lv_diff          boolean;
    i                pls_integer;
    j                pls_integer;
    k                pls_integer := 1;
    l                pls_integer := 1;
  begin
    bulk_tabcol_pvt(fv_table    => fv_table,
                    ft_metadata => lt_metadata);
    bulk_tabkey_pvt(fv_table     => fv_table,
                    ft_indexlist => lt_tabkey);
    i := lt_metadata.first;
    while (i is not null) loop
      fr_bundle.full_element(i).column_id := lt_metadata(i).column_id;
      fr_bundle.full_element(i).column_name := lt_metadata(i).column_name;
      pragma inline (argument_type_pvt, 'YES');
      fr_bundle.full_element(i).argument_type := argument_type_pvt(fr_metadata => lt_metadata(i));
      pragma inline (record_type_pvt, 'YES');
      fr_bundle.full_element(i).record_type := record_type_pvt(fr_metadata => lt_metadata(i));
      pragma inline (comparable_type_pvt, 'YES');
      fr_bundle.full_element(i).comparable := comparable_type_pvt(fr_metadata => lt_metadata(i));
      pragma inline (returnable_type_pvt, 'YES');
      fr_bundle.full_element(i).returnable := returnable_type_pvt(fr_metadata => lt_metadata(i));
      lv_diff := true;
      j := lt_tabkey.first;
      while (j is not null) loop
        if (lt_tabkey(j) = lt_metadata(i).column_name) then
          lv_diff := false;
          if (lt_tabkey(j) != 'R#WID') then
            fr_bundle.full_element(i).flag := 'PK ' || to_char(j-1) || '/' || to_char(lt_tabkey.count-1);
          end if;
          fr_bundle.pk_element(j).column_id := fr_bundle.full_element(i).column_id;
          fr_bundle.pk_element(j).column_name := fr_bundle.full_element(i).column_name;
          fr_bundle.pk_element(j).argument_type := fr_bundle.full_element(i).argument_type;
          fr_bundle.pk_element(j).record_type := fr_bundle.full_element(i).record_type;
          fr_bundle.pk_element(j).comparable := fr_bundle.full_element(i).comparable;
          fr_bundle.pk_element(j).returnable := fr_bundle.full_element(i).returnable;
        end if;
        j := lt_tabkey.next(j);
      end loop;
      if (lv_diff) then
        fr_bundle.diff_element(k).column_id := fr_bundle.full_element(i).column_id;
        fr_bundle.diff_element(k).column_name := fr_bundle.full_element(i).column_name;
        fr_bundle.diff_element(k).argument_type := fr_bundle.full_element(i).argument_type;
        fr_bundle.diff_element(k).record_type := fr_bundle.full_element(i).record_type;
        fr_bundle.diff_element(k).comparable := fr_bundle.full_element(i).comparable;
        fr_bundle.diff_element(k).returnable := fr_bundle.full_element(i).returnable;
        k := k + 1;
      end if;
      if (fr_bundle.full_element(i).returnable) then
        fr_bundle.ret_element(l).column_id := fr_bundle.full_element(i).column_id;
        fr_bundle.ret_element(l).column_name := fr_bundle.full_element(i).column_name;
        fr_bundle.ret_element(l).argument_type := fr_bundle.full_element(i).argument_type;
        fr_bundle.ret_element(l).record_type := fr_bundle.full_element(i).record_type;
        fr_bundle.ret_element(l).comparable := fr_bundle.full_element(i).comparable;
        fr_bundle.ret_element(l).returnable := fr_bundle.full_element(i).returnable;
        l := l + 1;
      end if;
      i := lt_metadata.next(i);
    end loop;
    parse_checkcon_pvt(fv_table      => fv_table,
                       ft_check_list => fr_bundle.check_list);
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end fill_metadata_pvt;

  ------------------------------------------------------------------
  -- FILL_BUNDLE_PVT
  ------------------------------------------------------------------
  procedure fill_bundle_pvt(fv_table   in varchar2,
                            fr_bundle  in out nocopy RecBundle)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.FILL_BUNDLE_PVT:';
    lv_table         plstring := upper(substr(fv_table, 1, 30));
  begin
    if (lv_table is null) then
      raise_application_error(-20888, 'fv_table argument cannot be null:' || $$plsql_line);
    end if;
    fetch_namespace_pvt(fv_table     => lv_table,
                        fr_namespace => fr_bundle.namespace);
    if (fr_bundle.namespace.api_name is null) then
      raise_application_error(-20888, 'Table: "' || lv_table ||'" not found:' || $$plsql_line);
    end if;
    fill_metadata_pvt(fv_table  => lv_table,
                      fr_bundle => fr_bundle);
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end fill_bundle_pvt;

  ------------------------------------------------------------------
  -- RESET_PVT
  ------------------------------------------------------------------
  procedure reset_pvt
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.RESET_PVT:';
  begin
    if (gv_plid is not null) then
      nksg_tempclob.free(fv_plid => gv_plid);
    end if;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end reset_pvt;

  ------------------------------------------------------------------
  -- PUT_PAYLOAD_PVT
  ------------------------------------------------------------------
  procedure put_payload_pvt(fv_data  in varchar2)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.PUT_PAYLOAD_PVT:';
  begin
    if (fv_data is not null) then
      nksg_tempclob.put_payload(fv_plid => gv_plid,
                                fv_data => fv_data);
    end if;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end put_payload_pvt;

  ------------------------------------------------------------------
  -- NEW_PAYLOAD_PVT
  ------------------------------------------------------------------
  procedure new_payload_pvt
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.NEW_PAYLOAD_PVT:';
  begin
    gv_plid := nksg_tempclob.new_payload;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end new_payload_pvt;

  ------------------------------------------------------------------
  -- PPVT: Pad with blanks
  ------------------------------------------------------------------
  function ppvt(fv_length  in pls_integer)
    return varchar2
  is
    lc__       constant varchar2(100) := $$plsql_unit || '.PPVT:';
    lv_result           plstring;
  begin
    lv_result := rpad(' ', fv_length);
    return lv_result;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end ppvt;

  ------------------------------------------------------------------
  -- LARGEST_COLNAME_PVT
  ------------------------------------------------------------------
  function largest_colname_pvt(ft_data  in ArrMetaData)
    return pls_integer
  is
    lc__       constant varchar2(100) := $$plsql_unit || '.LARGEST_COLNAME_PVT:';
    lv_result  pls_integer := 0;
    i          pls_integer := ft_data.first;
  begin
    while (i is not null) loop
      lv_result := greatest(lv_result, lengthb(ft_data(i).column_name));
      i := ft_data.next(i);
    end loop;
    return lv_result;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end largest_colname_pvt;
  ------------------------------------------------------------------
  function largest_colname_pvt(ft_data  in ArrElement)
    return pls_integer
  is
    lc__       constant varchar2(100) := $$plsql_unit || '.LARGEST_COLNAME_PVT:';
    lv_result  pls_integer := 0;
    i          pls_integer := ft_data.first;
  begin
    while (i is not null) loop
      lv_result := greatest(lv_result, lengthb(ft_data(i).column_name));
      i := ft_data.next(i);
    end loop;
    return lv_result;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end largest_colname_pvt;

  ------------------------------------------------------------------
  -- LARGEST_ARGTYPE_PVT
  ------------------------------------------------------------------
  function largest_argtype_pvt(ft_data  in ArrElement)
    return pls_integer
  is
    lc__       constant varchar2(100) := $$plsql_unit || '.LARGEST_ARGTYPE_PVT:';
    lv_result  pls_integer := 0;
    i          pls_integer := ft_data.first;
  begin
    while (i is not null) loop
      lv_result := greatest(lv_result, lengthb(ft_data(i).argument_type));
      i := ft_data.next(i);
    end loop;
    return lv_result;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end largest_argtype_pvt;

  ------------------------------------------------------------------
  -- LARGEST_RECTYPE_PVT
  ------------------------------------------------------------------
  function largest_rectype_pvt(ft_data  in ArrElement)
    return pls_integer
  is
    lc__       constant varchar2(100) := $$plsql_unit || '.LARGEST_RECTYPE_PVT:';
    lv_result  pls_integer := 0;
    i          pls_integer := ft_data.first;
  begin
    while (i is not null) loop
      lv_result := greatest(lv_result, lengthb(ft_data(i).record_type));
      i := ft_data.next(i);
    end loop;
    return lv_result;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end largest_rectype_pvt;

  ------------------------------------------------------------------
  -- IMPLEMENTATION_PVT
  ------------------------------------------------------------------
  procedure implementation_pvt(fr_bundle   in RecBundle,
                               fv_payload  in out nocopy clob)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.IMPLEMENTATION_PVT:';
    lc_table_u       constant plstring := upper(fr_bundle.namespace.table_name);
    lc_table_l       constant plstring := lower(fr_bundle.namespace.table_name);
    lc_api_u         constant plstring := upper(fr_bundle.namespace.api_name);
    lc_api_l         constant plstring := lower(fr_bundle.namespace.api_name);
    lv_buffer        plstring;
    lv_column        plstring;
    lv_argtype       plstring;
    lv_rectype       plstring;
    lv_flag          plstring;
    lv_colid         pls_integer;
    lv_lpad          pls_integer;
    lv_ipad          pls_integer;
    lv_largest_cn    pls_integer;
    lv_largest_rt    pls_integer;
    i                pls_integer;
  begin
    -------------------------
    << init_implementation >>
    -------------------------
    begin
      reset_pvt;
      new_payload_pvt;
    exception when others then
      raise_application_error(-20888, '<< init_implementation >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end init_implementation;
    ---------------------
    << declare_session >>
    ---------------------
    begin
      lv_buffer := 'create or replace package body ' || lc_api_l                                                || nl ||
                   'is'                                                                                         || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  -- NKSG: PL/SQL Simple Generator'                                                         || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  --  (c) Copyright 2017 Geraldo Viana (r4vrya@gmail.com)'                                  || nl ||
                   '  --'                                                                                       || nl ||
                   '  --  Licensed under the Apache License, Version 2.0 (the "License"):'                      || nl ||
                   '  --  you may not use this file except in compliance with the License.'                     || nl ||
                   '  --  You may obtain a copy of the License at'                                              || nl ||
                   '  --'                                                                                       || nl ||
                   '  --      http://www.apache.org/licenses/LICENSE-2.0'                                       || nl ||
                   '  --'                                                                                       || nl ||
                   '  --  Unless required by applicable law or agreed to in writing, software'                  || nl ||
                   '  --  distributed under the License is distributed on an "AS IS" BASIS,'                    || nl ||
                   '  --  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.'             || nl ||
                   '  --  See the License for the specific language governing permissions and'                  || nl ||
                   '  --  limitations under the License.'                                                       || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  -- ' || lc_api_u || ': ' || lc_table_u || ' Simple CRUD API'                              || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   ''                                                                                           || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  ------------------------ Declare Session -------------------------'                       || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  -- Local constants'                                                                       || nl ||
                   '  nl       constant varchar2(1) := '''                                                      || nl ||
                   ''';'                                                                                        || nl ||
                   '  gc_limit constant pls_integer := 1e3; -- FORALL collection limit: 1000'                   || nl ||
                   ''                                                                                           || nl ||
                   '  -- Local types'                                                                           || nl ||
                   '  type weak_refcursor is ref cursor;'                                                       || nl ||
                   '  type plstring_list  is table of plstring index by pls_integer;'                           || nl ||
                   ''                                                                                           || nl ||
                   '  -- Exceptions'                                                                            || nl ||
                   '  lock_timeout     exception;'                                                              || nl ||
                   '  pragma exception_init(lock_timeout, -30006);    '
                   || '-- ORA-30006: resource busy; acquire with WAIT timeout expired'                          || nl ||
                   '  lock_nowait      exception;'                                                              || nl ||
                   '  pragma exception_init(lock_nowait, -54);        '
                   || '-- ORA-00054: resource busy and acquire with NOWAIT specified'                           || nl ||
                   '  dml_error        exception;'                                                              || nl ||
                   '  pragma exception_init(dml_error, -24381);       '
                   || '-- ORA-24381: error(s) in array DML'                                                     || nl ||
                   ''                                                                                           || nl ||
                   '  -- Stateful Scalars/Containers'                                                           || nl ||
                   '  --gt_rowid    plstring_map;    -- keep stateless when no ID PK'                           || nl ||
                   ''                                                                                           || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  ------------------------ Private Session -------------------------'                       || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< declare_session >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end declare_session;
    ------------------------
    << bulk_exception_pvt >>
    ------------------------
    begin
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- BULK_EXCEPTION_PVT'                                                                    || nl ||
                   '  -- *** TODO ***'                                                                          || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  --procedure bulk_exception_pvt(ft_error  in out nocopy plstring_list)'                    || nl ||
                   '  --is'                                                                                     || nl ||
                   '  --  lc__    constant varchar2(100) := $$plsql_unit || ''.BULK_EXCEPTION_PVT:'';'          || nl ||
                   '  --  j                pls_integer;'                                                        || nl ||
                   '  --begin'                                                                                  || nl ||
                   '  --  for i in 1 .. sql%bulk_exceptions.count loop'                                         || nl ||
                   '  --    j := sql%bulk_exceptions(i).error_index;'                                           || nl ||
                   '  --    ft_error(j) := sqlerrm(-sql%bulk_exceptions(i).error_code);'                        || nl ||
                   '  --  end loop;'                                                                            || nl ||
                   '  --exception when others then'                                                             || nl ||
                   '  --  raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  --end bulk_exception_pvt;'                                                                || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< bulk_exception_pvt >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end bulk_exception_pvt;
    ----------------------
    << inspect_data_pvt >>
    ----------------------
    begin
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- INSPECT_DATA_PVT'                                                                      || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure inspect_data_pvt(fr_data  in out nocopy RecData)'                               || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__    constant varchar2(100) := $$plsql_unit || ''.INSPECT_DATA_PVT:'';'              || nl ||
                   '  begin'                                                                                    || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.check_list.first;
      while (i is not null) loop
        if (i = fr_bundle.check_list.first) then
          lv_buffer := '    if ' || fr_bundle.check_list(i);
        else
          lv_buffer := '    elsif ' || fr_bundle.check_list(i);
        end if;
        put_payload_pvt(lv_buffer);
        i := fr_bundle.check_list.next(i);
      end loop;
      lv_buffer := '    end if;'                                                                                || nl ||
                   '    -- include defaults and sanities below this line...'                                    || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end inspect_data_pvt;'                                                                    || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< inspect_data_pvt >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end inspect_data_pvt;
    --------------------
    << inspect_id_pvt >>
    --------------------
    begin
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- INSPECT_ID_PVT'                                                                        || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure inspect_id_pvt(fr_id  in RecID)'                                                || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__    constant varchar2(100) := $$plsql_unit || ''.INSPECT_ID_PVT:'';'                || nl ||
                   '  begin'                                                                                    || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.pk_element.first;
      while (i is not null) loop
        lv_column := lower(fr_bundle.pk_element(i).column_name);
        if (i = fr_bundle.pk_element.first) then
          lv_buffer := '    if (fr_id.' || lv_column || ' is null) then'                                        || nl ||
                       '      raise_application_error(-20888, ''fr_id.' || lv_column
                       || ' cannot be null:'' || $$plsql_line);'                                                || nl;
        else
          lv_buffer := '    elsif (fr_id.' || lv_column || ' is null) then'                                     || nl ||
                       '      raise_application_error(-20888, ''fr_id.' || lv_column
                       || ' cannot be null:'' || $$plsql_line);'                                                || nl;
        end if;
        put_payload_pvt(lv_buffer);
        i := fr_bundle.pk_element.next(i);
      end loop;
      lv_buffer := '    end if;'                                                                                || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end inspect_id_pvt;'                                                                      || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< inspect_id_pvt >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end inspect_id_pvt;
    --------------------
    << select_row_pvt >>
    --------------------
    begin
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- SELECT_ROW_PVT'                                                                        || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure select_row_pvt(fr_data  in out nocopy RecData)'                                 || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__    constant varchar2(100) := $$plsql_unit || ''.SELECT_INSTANCE_PVT:'';'           || nl ||
                   '    lv_refcur        weak_refcursor;'                                                       || nl ||
                   '  begin'                                                                                    || nl ||
                   '    open lv_refcur for'                                                                     || nl ||
                   '    select --+ choose'                                                                      || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.full_element.first;
      if (i is not null) then
        i := fr_bundle.full_element.next(i);    -- skip "R#WID"
        lv_buffer := '           a.rowid,' || ppvt(77) || '--000 urowid'                                        || nl;
        put_payload_pvt(lv_buffer);
        while (i is not null) loop
          lv_colid := lower(fr_bundle.full_element(i).column_id);
          lv_column := lower(fr_bundle.full_element(i).column_name);
          lv_rectype := fr_bundle.full_element(i).record_type;
          lv_ipad := 81 - lengthb(lv_column);
          lv_buffer := '           a.' || lv_column || s# || ppvt(lv_ipad) || ' --'
                       || trim(to_char(lv_colid, '000')) || ' ' || lv_rectype                                   || nl;
          if (i != fr_bundle.full_element.last) then
            lv_buffer := replace(lv_buffer, s#, ',');
          else
            lv_buffer := replace(lv_buffer, s#, ' ');
          end if;
          put_payload_pvt(lv_buffer);
          i := fr_bundle.full_element.next(i);
        end loop;
      end if;
      lv_buffer := '      from ' || lc_table_l || '    a'                                                       || nl ||
                   '     where 1e1 = 1e1'                                                                       || nl ||
                   '       and (fr_data.r#wid is null or a.rowid = fr_data.r#wid)'
                   || ppvt(35) || '--000 urowid'                                                                || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.pk_element.first;
      if (i is not null) then
        i := fr_bundle.pk_element.next(i);    -- skip "R#WID"
        while (i is not null) loop
          lv_colid := lower(fr_bundle.pk_element(i).column_id);
          lv_column := lower(fr_bundle.pk_element(i).column_name);
          lv_rectype := fr_bundle.pk_element(i).record_type;
          lv_ipad := 70 - (2 * lengthb(lv_column));
          lv_buffer := '       and a.' || lv_column || ' = fr_data.' || lv_column || s# || ppvt(lv_ipad)
                        || ' --' || trim(to_char(lv_colid, '000')) || ' ' || lv_rectype                         || nl;
          if (i != fr_bundle.pk_element.last) then
            lv_buffer := replace(lv_buffer, s#, ' ');
          else
            lv_buffer := replace(lv_buffer, s#, ';');
          end if;
          put_payload_pvt(lv_buffer);
          i := fr_bundle.pk_element.next(i);
        end loop;
      end if;
      lv_buffer := '    fetch lv_refcur into fr_data;'                                                          || nl ||
                   '    close lv_refcur;'                                                                       || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    if (lv_refcur%isopen) then'                                                             || nl ||
                   '      close lv_refcur;'                                                                     || nl ||
                   '    end if;'                                                                                || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end select_row_pvt;'                                                                      || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< select_row_pvt >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end select_row_pvt;
    ------------------------
    << select_locking_pvt >>
    ------------------------
    begin
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- SELECT_LOCKING_PVT'                                                                    || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure select_locking_pvt(fr_data  in out nocopy RecData)'                             || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__    constant varchar2(100) := $$plsql_unit || ''.SELECT_LOCKING_PVT:'';'            || nl ||
                   '    lv_refcur        weak_refcursor;'                                                       || nl ||
                   '  begin'                                                                                    || nl ||
                   '    open lv_refcur for'                                                                     || nl ||
                   '    select --+ choose'                                                                      || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.full_element.first;
      if (i is not null) then
        i := fr_bundle.full_element.next(i);    -- skip "R#WID"
        lv_buffer := '           a.rowid,' || ppvt(77) || '--000 urowid'                                        || nl;
        put_payload_pvt(lv_buffer);
        while (i is not null) loop
          lv_colid := lower(fr_bundle.full_element(i).column_id);
          lv_column := lower(fr_bundle.full_element(i).column_name);
          lv_rectype := fr_bundle.full_element(i).record_type;
          lv_ipad := 81 - lengthb(lv_column);
          lv_buffer := '           a.' || lv_column || s# || ppvt(lv_ipad) || ' --'
                       || trim(to_char(lv_colid, '000')) || ' ' || lv_rectype                                   || nl;
          if (i != fr_bundle.full_element.last) then
            lv_buffer := replace(lv_buffer, s#, ',');
          else
            lv_buffer := replace(lv_buffer, s#, ' ');
          end if;
          put_payload_pvt(lv_buffer);
          i := fr_bundle.full_element.next(i);
        end loop;
      end if;
      lv_buffer := '      from ' || lc_table_l || '    a'                                                       || nl ||
                   '     where 1e1 = 1e1'                                                                       || nl ||
                   '       and (fr_data.r#wid is null or a.rowid = fr_data.r#wid)'
                   || ppvt(35) || '--000 urowid'                                                                || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.pk_element.first;
      if (i is not null) then
        i := fr_bundle.pk_element.next(i);    -- skip "R#WID"
        while (i is not null) loop
          lv_colid := lower(fr_bundle.pk_element(i).column_id);
          lv_column := lower(fr_bundle.pk_element(i).column_name);
          lv_rectype := fr_bundle.pk_element(i).record_type;
          lv_ipad := 71 - (2 * lengthb(lv_column));
          lv_buffer := '       and a.' || lv_column || ' = fr_data.' || lv_column || ppvt(lv_ipad)
                        || ' --' || trim(to_char(lv_colid, '000')) || ' ' || lv_rectype                         || nl;
          put_payload_pvt(lv_buffer);
          i := fr_bundle.pk_element.next(i);
        end loop;
      end if;
      lv_buffer := '       for update wait 4;'                                                                  || nl ||
                   '    fetch lv_refcur into fr_data;'                                                          || nl ||
                   '    close lv_refcur;'                                                                       || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    if (lv_refcur%isopen) then'                                                             || nl ||
                   '      close lv_refcur;'                                                                     || nl ||
                   '    end if;'                                                                                || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end select_locking_pvt;'                                                                  || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< select_locking_pvt >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end select_locking_pvt;
    --------------------
    << exists_row_pvt >>
    --------------------
    begin
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- EXISTS_ROW_PVT'                                                                        || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  function exists_row_pvt(fr_id  in RecID)'                                                 || nl ||
                   '    return boolean'                                                                         || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__   constant varchar2(100) := $$plsql_unit || ''.EXISTS_ROW_PVT:'';'                 || nl ||
                   '    lv_refcur       weak_refcursor;'                                                        || nl ||
                   '    lv_null         varchar2(1);'                                                           || nl ||
                   '    lv_found        boolean := false;'                                                      || nl ||
                   '  begin'                                                                                    || nl ||
                   '    open lv_refcur for'                                                                     || nl ||
                   '    select --+ rowid(a)'                                                                    || nl ||
                   '           null'                                                                            || nl ||
                   '      from ' || lc_table_l || '    a'                                                       || nl ||
                   '     where 1e1 = 1e1'                                                                       || nl ||
                   '       and (fr_id.r#wid is null or a.rowid = fr_id.r#wid)' || ppvt(39) || '--000 urowid'    || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.pk_element.first;
      if (i is not null) then
        i := fr_bundle.pk_element.next(i);    -- skip "R#WID"
        while (i is not null) loop
          lv_colid := lower(fr_bundle.pk_element(i).column_id);
          lv_column := lower(fr_bundle.pk_element(i).column_name);
          lv_rectype := fr_bundle.pk_element(i).record_type;
          lv_ipad := 72 - (2 * lengthb(lv_column));
          lv_buffer := '       and a.' || lv_column || ' = fr_id.' || lv_column || s# || ppvt(lv_ipad)
                        || ' --' || trim(to_char(lv_colid, '000')) || ' ' || lv_rectype                         || nl;
          if (i != fr_bundle.pk_element.last) then
            lv_buffer := replace(lv_buffer, s#, ' ');
          else
            lv_buffer := replace(lv_buffer, s#, ';');
          end if;
          put_payload_pvt(lv_buffer);
          i := fr_bundle.pk_element.next(i);
        end loop;
      end if;
      lv_buffer := '    fetch lv_refcur into lv_null;'                                                          || nl ||
                   '    lv_found := lv_refcur%found;'                                                           || nl ||
                   '    close lv_refcur;'                                                                       || nl ||
                   '    return lv_found;'                                                                       || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    if (lv_refcur%isopen) then'                                                             || nl ||
                   '      close lv_refcur;'                                                                     || nl ||
                   '    end if;'                                                                                || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end exists_row_pvt;'                                                                      || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< exists_row_pvt >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end exists_row_pvt;
    --------------------
    << delete_row_pvt >>
    --------------------
    begin
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- DELETE_ROW_PVT'                                                                        || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure delete_row_pvt(fr_id  in RecID)'                                                || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__    constant varchar2(100) := $$plsql_unit || ''.DELETE_ROW_PVT:'';'                || nl ||
                   '  begin'                                                                                    || nl ||
                   '    delete --+ rowid(a)'                                                                    || nl ||
                   '      from ' || lc_table_l || '    a'                                                       || nl ||
                   '     where 1e1 = 1e1'                                                                       || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.pk_element.first;
      while (i is not null) loop
        lv_colid := lower(fr_bundle.pk_element(i).column_id);
        lv_column := lower(fr_bundle.pk_element(i).column_name);
        lv_rectype := fr_bundle.pk_element(i).record_type;
        lv_ipad := 72 - (2 * lengthb(lv_column));
        if (i = fr_bundle.pk_element.first) then
          lv_buffer := '       and a.rowid = fr_id.r#wid' || ppvt(64) || '--000 urowid'                         || nl;
        else
          lv_buffer := '       and a.' || lv_column || ' = fr_id.' || lv_column || s# || ppvt(lv_ipad)
                       || ' --' || trim(to_char(lv_colid, '000')) || ' ' || lv_rectype                          || nl;
        end if;
        if (i != fr_bundle.pk_element.last) then
          lv_buffer := replace(lv_buffer, s#, ' ');
        else
          lv_buffer := replace(lv_buffer, s#, ';');
        end if;
        put_payload_pvt(lv_buffer);
        i := fr_bundle.pk_element.next(i);
      end loop;
      lv_buffer := '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end delete_row_pvt;'                                                                      || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< delete_row_pvt >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end delete_row_pvt;
    --------------------
    << update_row_pvt >>
    --------------------
    begin
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- UPDATE_ROW_PVT'                                                                        || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure update_row_pvt(fr_data  in out nocopy RecData)'                                 || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__    constant varchar2(100) := $$plsql_unit || ''.UPDATE_ROW_PVT:'';'                || nl ||
                   '  begin'                                                                                    || nl ||
                   '    update --+ rowid(a)'                                                                    || nl ||
                   '           ' || lc_table_l || '    a'                                                       || nl ||
                   '       set -- set-list'                                                                     || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.diff_element.first;
      while (i is not null) loop
        lv_colid := lower(fr_bundle.diff_element(i).column_id);
        lv_column := lower(fr_bundle.diff_element(i).column_name);
        lv_rectype := fr_bundle.diff_element(i).record_type;
        lv_ipad := 70 - (2 * lengthb(lv_column));
        lv_buffer := '           a.' || lv_column || ' = fr_data.' || lv_column || s# || ppvt(lv_ipad)
                     || ' --' || trim(to_char(lv_colid, '000')) || ' ' || lv_rectype                            || nl;
        if (i != fr_bundle.diff_element.last) then
          lv_buffer := replace(lv_buffer, s#, ',');
        else
          lv_buffer := replace(lv_buffer, s#, ' ');
        end if;
        put_payload_pvt(lv_buffer);
        i := fr_bundle.diff_element.next(i);
      end loop;
      lv_buffer := '     where 1e1 = 1e1'                                                                       || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.pk_element.first;
      while (i is not null) loop
        lv_colid := lower(fr_bundle.pk_element(i).column_id);
        lv_column := lower(fr_bundle.pk_element(i).column_name);
        lv_rectype := fr_bundle.pk_element(i).record_type;
        lv_ipad := 71 - (2 * lengthb(lv_column));
        if (i = fr_bundle.pk_element.first) then
          lv_buffer := '       and a.rowid = fr_data.r#wid' || ppvt(62) || '--000 urowid'                       || nl;
        else
          lv_buffer := '       and a.' || lv_column || ' = fr_data.' || lv_column || ppvt(lv_ipad)
                       || ' --' || trim(to_char(lv_colid, '000')) || ' ' || lv_rectype                          || nl;
        end if;
        put_payload_pvt(lv_buffer);
        i := fr_bundle.pk_element.next(i);
      end loop;
      lv_buffer := '    returning'                                                                              || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.ret_element.first;
      if (i is not null) then
        i := fr_bundle.ret_element.next(i);    -- skip "R#WID"
        lv_buffer := '           rowid,' || ppvt(79) || '--000 urowid'                                          || nl;
        put_payload_pvt(lv_buffer);
        while (i is not null) loop
          lv_colid := lower(fr_bundle.ret_element(i).column_id);
          lv_column := lower(fr_bundle.ret_element(i).column_name);
          lv_rectype := fr_bundle.ret_element(i).record_type;
          lv_ipad := 83 - lengthb(lv_column);
          lv_buffer := '           ' || lv_column || s# || ppvt(lv_ipad) || ' --'
                       || trim(to_char(lv_colid, '000')) || ' ' || lv_rectype                                   || nl;
          if (i != fr_bundle.ret_element.last) then
            lv_buffer := replace(lv_buffer, s#, ',');
          else
            lv_buffer := replace(lv_buffer, s#, ' ');
          end if;
          put_payload_pvt(lv_buffer);
          i := fr_bundle.ret_element.next(i);
        end loop;
      end if;
      lv_buffer := '      into'                                                                                 || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.ret_element.first;
      while (i is not null) loop
        lv_colid := lower(fr_bundle.ret_element(i).column_id);
        lv_column := lower(fr_bundle.ret_element(i).column_name);
        lv_rectype := fr_bundle.ret_element(i).record_type;
        lv_ipad := 75 - lengthb(lv_column);
        lv_buffer := '           fr_data.' || lv_column || s# || ppvt(lv_ipad) || ' --'
                     || trim(to_char(lv_colid, '000')) || ' ' || lv_rectype                                     || nl;
        if (i != fr_bundle.ret_element.last) then
          lv_buffer := replace(lv_buffer, s#, ',');
        else
          lv_buffer := replace(lv_buffer, s#, ';');
        end if;
        put_payload_pvt(lv_buffer);
        i := fr_bundle.ret_element.next(i);
      end loop;
      lv_buffer := '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end update_row_pvt;'                                                                      || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< update_row_pvt >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end update_row_pvt;
    ------------------
    << lock_row_pvt >>
    ------------------
    begin
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- LOCK_ROW_PVT'                                                                          || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure lock_row_pvt(fr_id  in RecID)'                                                  || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__    constant varchar2(100) := $$plsql_unit || ''.LOCK_ROW_PVT:'';'                  || nl ||
                   '    lv_refcur        weak_refcursor;'                                                       || nl ||
                   '  begin'                                                                                    || nl ||
                   '    begin'                                                                                  || nl ||
                   '      open lv_refcur for'                                                                   || nl ||
                   '      select --+ rowid(a)'                                                                  || nl ||
                   '             null'                                                                          || nl ||
                   '        from ' || lc_table_l || '    a'                                                     || nl ||
                   '       where 1e1 = 1e1'                                                                     || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.pk_element.first;
      while (i is not null) loop
        lv_colid := lower(fr_bundle.pk_element(i).column_id);
        lv_column := lower(fr_bundle.pk_element(i).column_name);
        lv_rectype := fr_bundle.pk_element(i).record_type;
        lv_ipad := 71 - (2 * lengthb(lv_column));
        if (i = fr_bundle.pk_element.first) then
          lv_buffer := '         and a.rowid = fr_id.r#wid' || ppvt(62) || '--000 urowid'                       || nl;
        else
          lv_buffer := '         and a.' || lv_column || ' = fr_id.' || lv_column || ppvt(lv_ipad)
                       || ' --' || trim(to_char(lv_colid, '000')) || ' ' || lv_rectype                          || nl;
        end if;
        put_payload_pvt(lv_buffer);
        i := fr_bundle.pk_element.next(i);
      end loop;
      lv_buffer := '      for update wait 4;'                                                                   || nl ||
                   '      close lv_refcur;'                                                                     || nl ||
                   '    exception'                                                                              || nl ||
                   '      when lock_nowait or lock_timeout then'                                                || nl ||
                   '        raise_application_error(-20888, ''rowid['' || rowidtochar(fr_id.r#wid)'             || nl ||
                   '                                || ''] locked by another session:'' || $$plsql_line);'      || nl ||
                   '      when others then'                                                                     || nl ||
                   '        raise;'                                                                             || nl ||
                   '    end;'                                                                                   || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    if (lv_refcur%isopen) then'                                                             || nl ||
                   '      close lv_refcur;'                                                                     || nl ||
                   '    end if;'                                                                                || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end lock_row_pvt;'                                                                        || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< lock_row_pvt >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end lock_row_pvt;
    ------------------
    << lock_all_pvt >>
    ------------------
    begin
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- LOCK_ALL_PVT'                                                                          || nl ||
                   '  -- *** TODO ***'                                                                          || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  --procedure lock_all_pvt'                                                                 || nl ||
                   '  --is'                                                                                     || nl ||
                   '  --  lc__    constant varchar2(100) := $$plsql_unit || ''.LOCK_ALL_PVT:'';'                || nl ||
                   '  --  lv_refcur        weak_refcursor;'                                                     || nl ||
                   '  --begin'                                                                                  || nl ||
                   '  --  begin'                                                                                || nl ||
                   '  --    open lv_refcur for'                                                                 || nl ||
                   '  --    select --+ rowid(a)'                                                                || nl ||
                   '  --           null'                                                                        || nl ||
                   '  --      from ' || lc_table_l || '    a'                                                   || nl ||
                   '  --     where 1e1 = 1e1'                                                                   || nl ||
                   '  --       and (a.rowid, a.id) in (select --+ dynamic_sampling(p, 10)'                      || nl ||
                   '  --                                      chartorowid(p.map_item),'                         || nl ||
                   '  --                                      to_number(p.map_value)'                           || nl ||
                   '  --                                 from table(nksg_dmlapi.pipe_rowid)    p'               || nl ||
                   '  --                                where 1e1 = 1e1)'                                       || nl ||
                   '  --       for update wait 4;'                                                              || nl ||
                   '  --    close lv_refcur;'                                                                   || nl ||
                   '  --  exception'                                                                            || nl ||
                   '  --    when lock_nowait or lock_timeout then'                                              || nl ||
                   '  --      raise_application_error(-20888, ''Some element in collection has been'
                   || ' locked by another session:'' || $$plsql_line);'                                         || nl ||
                   '  --    when others then'                                                                   || nl ||
                   '  --      raise;'                                                                           || nl ||
                   '  --  end;'                                                                                 || nl ||
                   '  --exception when others then'                                                             || nl ||
                   '  --  if (lv_refcur%isopen) then'                                                           || nl ||
                   '  --    close lv_refcur;'                                                                   || nl ||
                   '  --  end if;'                                                                              || nl ||
                   '  --  raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  --end lock_all_pvt;'                                                                      || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< lock_all_pvt >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end lock_all_pvt;
    --------------------
    << public_session >>
    --------------------
    begin
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  ------------------------ Public Session --------------------------'                       || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< public_session >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end public_session;
    ----------------
    << exists_row >>
    ----------------
    begin
      lv_lpad := 4;
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- EXISTS_ROW'                                                                            || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  function exists_row(fr_id  in RecID)'                                                     || nl ||
                   '    return boolean'                                                                         || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__   constant varchar2(100) := $$plsql_unit || ''.EXISTS_ROW:'';'                     || nl ||
                   '  begin'                                                                                    || nl ||
                   '    inspect_id_pvt(fr_id  => fr_id);'                                                       || nl ||
                   '    return exists_row_pvt(fr_id => fr_id);'                                                 || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end exists_row;'                                                                          || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  function exists_row(fr_data  in RecData)'                                                 || nl ||
                   '    return boolean'                                                                         || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__   constant varchar2(100) := $$plsql_unit || ''.EXISTS_ROW:'';'                     || nl ||
                   '    lr_id           RecID;'                                                                 || nl ||
                   '  begin'                                                                                    || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.pk_element.first;
      while (i is not null) loop
        lv_column := lower(fr_bundle.pk_element(i).column_name);
        lv_buffer := '    lr_id.' || lv_column || ' := fr_data.' || lv_column || ';' || nl;
        put_payload_pvt(lv_buffer);
        i := fr_bundle.pk_element.next(i);
      end loop;
      lv_buffer := '    inspect_id_pvt(fr_id => lr_id);'                                                        || nl ||
                   '    return exists_row_pvt(fr_id => lr_id);'                                                 || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end exists_row;'                                                                          || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< exists_row >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end exists_row;
    ----------------
    << select_row >>
    ----------------
    begin
      lv_lpad := 4;
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- SELECT_ROW'                                                                            || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure select_row(fr_data  in out nocopy RecData,'                                     || nl ||
                   '                       fv_lock  in boolean default false)'                                  || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__    constant varchar2(100) := $$plsql_unit || ''.SELECT_ROW:'';'                    || nl ||
                   '    lr_id            RecID;'                                                                || nl ||
                   '  begin'                                                                                    || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.pk_element.first;
      while (i is not null) loop
        lv_column := lower(fr_bundle.pk_element(i).column_name);
        lv_buffer := '    lr_id.' || lv_column || ' := fr_data.' || lv_column || ';' || nl;
        put_payload_pvt(lv_buffer);
        i := fr_bundle.pk_element.next(i);
      end loop;
      lv_buffer := '    inspect_id_pvt(fr_id => lr_id);'                                                        || nl ||
                   '    if (fv_lock) then'                                                                      || nl ||
                   '      select_locking_pvt(fr_data => fr_data);'                                              || nl ||
                   '    else'                                                                                   || nl ||
                   '      select_row_pvt(fr_data => fr_data);'                                                  || nl ||
                   '    end if;'                                                                                || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end select_row;'                                                                          || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< select_row >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end select_row;
    ----------------
    << insert_row >>
    ----------------
    begin
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- INSERT_ROW'                                                                            || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure insert_row(fr_data  in out nocopy RecData)'                                     || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__    constant varchar2(100) := $$plsql_unit || ''.INSERT_ROW:'';'                    || nl ||
                   '  begin'                                                                                    || nl ||
                   '    inspect_data_pvt(fr_data => fr_data);'                                                  || nl ||
                   '    insert into ' || lc_table_l                                                             || nl ||
                   '      ( -- column-list'                                                                     || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.full_element.first;
      if (i is not null) then
        i := fr_bundle.full_element.next(i);    -- skip "R#WID"
        while (i is not null) loop
          lv_colid := lower(fr_bundle.full_element(i).column_id);
          lv_column := lower(fr_bundle.full_element(i).column_name);
          lv_rectype := fr_bundle.full_element(i).record_type;
          lv_ipad := 86 - lengthb(lv_column);
          lv_buffer := '        ' || lv_column || s# || ppvt(lv_ipad) || ' --'
                       || trim(to_char(lv_colid, '000')) || ' ' || lv_rectype                                   || nl;
          if (i != fr_bundle.full_element.last) then
            lv_buffer := replace(lv_buffer, s#, ',');
          else
            lv_buffer := replace(lv_buffer, s#, ')');
          end if;
          put_payload_pvt(lv_buffer);
          i := fr_bundle.full_element.next(i);
        end loop;
      end if;
      lv_buffer := '    values'                                                                                 || nl ||
                   '      ( -- value-list'                                                                      || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.full_element.first;
      if (i is not null) then
        i := fr_bundle.full_element.next(i);    -- skip "R#WID"
        while (i is not null) loop
          lv_colid := lower(fr_bundle.full_element(i).column_id);
          lv_column := lower(fr_bundle.full_element(i).column_name);
          lv_rectype := fr_bundle.full_element(i).record_type;
          lv_ipad := 78 - lengthb(lv_column);
          lv_buffer := '        fr_data.' || lv_column || s# || ppvt(lv_ipad) || ' --'
                       || trim(to_char(lv_colid, '000')) || ' ' || lv_rectype                                   || nl;
          if (i != fr_bundle.full_element.last) then
            lv_buffer := replace(lv_buffer, s#, ',');
          else
            lv_buffer := replace(lv_buffer, s#, ')');
          end if;
          put_payload_pvt(lv_buffer);
          i := fr_bundle.full_element.next(i);
        end loop;
      end if;
      lv_buffer := '    returning'                                                                              || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.ret_element.first;
      if (i is not null) then
        i := fr_bundle.ret_element.next(i);    -- skip "R#WID"
        lv_buffer := '        rowid,' || ppvt(82) || '--000 urowid'                                             || nl;
        put_payload_pvt(lv_buffer);
        while (i is not null) loop
          lv_colid := lower(fr_bundle.ret_element(i).column_id);
          lv_column := lower(fr_bundle.ret_element(i).column_name);
          lv_rectype := fr_bundle.ret_element(i).record_type;
          lv_ipad := 86 - lengthb(lv_column);
          lv_buffer := '        ' || lv_column || s# || ppvt(lv_ipad) || ' --'
                       || trim(to_char(lv_colid, '000')) || ' ' || lv_rectype                                   || nl;
          if (i != fr_bundle.ret_element.last) then
            lv_buffer := replace(lv_buffer, s#, ',');
          else
            lv_buffer := replace(lv_buffer, s#, ' ');
          end if;
          put_payload_pvt(lv_buffer);
          i := fr_bundle.ret_element.next(i);
        end loop;
      end if;
      lv_buffer := '    into'                                                                                   || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.ret_element.first;
      while (i is not null) loop
        lv_colid := lower(fr_bundle.ret_element(i).column_id);
        lv_column := lower(fr_bundle.ret_element(i).column_name);
        lv_rectype := fr_bundle.ret_element(i).record_type;
        lv_ipad := 78 - lengthb(lv_column);
        lv_buffer := '        fr_data.' || lv_column || s# || ppvt(lv_ipad) || ' --'
                     || trim(to_char(lv_colid, '000')) || ' ' || lv_rectype                                     || nl;
        if (i != fr_bundle.ret_element.last) then
          lv_buffer := replace(lv_buffer, s#, ',');
        else
          lv_buffer := replace(lv_buffer, s#, ';');
        end if;
        put_payload_pvt(lv_buffer);
        i := fr_bundle.ret_element.next(i);
      end loop;
      lv_buffer := '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end insert_row;'                                                                          || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< insert_row >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end insert_row;
    ----------------
    << insert_all >>
    ----------------
    begin
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- INSERT_ALL'                                                                            || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure insert_all(ft_data    in out nocopy ArrData,'                                   || nl ||
                   '                       fv_rebind  in boolean default false)'                                || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__    constant varchar2(100) := $$plsql_unit || ''.INSERT_ALL:'';'                    || nl ||
                   '    lt_rowid         plstring_list;'                                                        || nl ||
                   '    i                pls_integer;'                                                          || nl ||
                   '  begin'                                                                                    || nl ||
                   '    ------------'                                                                           || nl ||
                   '    << sanity >>'                                                                           || nl ||
                   '    ------------'                                                                           || nl ||
                   '    begin'                                                                                  || nl ||
                   '      if (ft_data.count > gc_limit) then'                                                   || nl ||
                   '        raise_application_error(-20888, ''ft_data.count() is limited to '''                 || nl ||
                   '                                        || to_char(gc_limit) || '' elements:'''
                   || ' || $$plsql_line);'                                                                      || nl ||
                   '      end if;'                                                                              || nl ||
                   '      i := ft_data.first;'                                                                  || nl ||
                   '      while (i is not null) loop'                                                           || nl ||
                   '        pragma inline (inspect_data_pvt, ''YES'');'                                         || nl ||
                   '        inspect_data_pvt(fr_data => ft_data(i));'                                           || nl ||
                   '        i := ft_data.next(i);'                                                              || nl ||
                   '      end loop;'                                                                            || nl ||
                   '    exception when others then'                                                             || nl ||
                   '      raise_application_error(-20777, ''<< sanity >>:'' ||'
                   || ' $$plsql_line || nl || dbms_utility.format_error_stack);'                                || nl ||
                   '    end sanity;'                                                                            || nl ||
                   '    -----------------'                                                                      || nl ||
                   '    << forall_call >>'                                                                      || nl ||
                   '    -----------------'                                                                      || nl ||
                   '    begin'                                                                                  || nl ||
                   '      forall i in indices of ft_data'                                                       || nl ||
                   '      insert into ' || lc_table_l                                                           || nl ||
                   '      ( -- column-list'                                                                     || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.full_element.first;
      if (i is not null) then
        i := fr_bundle.full_element.next(i);    -- skip "R#WID"
        while (i is not null) loop
          lv_colid := lower(fr_bundle.full_element(i).column_id);
          lv_column := lower(fr_bundle.full_element(i).column_name);
          lv_rectype := fr_bundle.full_element(i).record_type;
          lv_ipad := 86 - lengthb(lv_column);
          lv_buffer := '        ' || lv_column || s# || ppvt(lv_ipad) || ' --'
                       || trim(to_char(lv_colid, '000')) || ' ' || lv_rectype                                   || nl;
          if (i != fr_bundle.full_element.last) then
            lv_buffer := replace(lv_buffer, s#, ',');
          else
            lv_buffer := replace(lv_buffer, s#, ')');
          end if;
          put_payload_pvt(lv_buffer);
          i := fr_bundle.full_element.next(i);
        end loop;
      end if;
      lv_buffer := '      values'                                                                               || nl ||
                   '      ( -- value-list'                                                                      || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.full_element.first;
      if (i is not null) then
        i := fr_bundle.full_element.next(i);    -- skip "R#WID"
        while (i is not null) loop
          lv_colid := lower(fr_bundle.full_element(i).column_id);
          lv_column := lower(fr_bundle.full_element(i).column_name);
          lv_rectype := fr_bundle.full_element(i).record_type;
          lv_ipad := 75 - lengthb(lv_column);
          lv_buffer := '        ft_data(i).' || lv_column || s# || ppvt(lv_ipad) || ' --'
                       || trim(to_char(lv_colid, '000')) || ' ' || lv_rectype                                   || nl;
          if (i != fr_bundle.full_element.last) then
            lv_buffer := replace(lv_buffer, s#, ',');
          else
            lv_buffer := replace(lv_buffer, s#, ')');
          end if;
          put_payload_pvt(lv_buffer);
          i := fr_bundle.full_element.next(i);
        end loop;
      end if;
      lv_buffer := '      returning chartorowid(rowid) bulk collect into lt_rowid; '                            || nl ||
                   '    exception when others then'                                                             || nl ||
                   '      raise_application_error(-20777, ''<< forall_call >>:'' '
                   || '|| $$plsql_line || nl || dbms_utility.format_error_stack);'                              || nl ||
                   '    end forall_call;'                                                                       || nl ||
                   '    ----------------'                                                                       || nl ||
                   '    << rowid_bind >>'                                                                       || nl ||
                   '    ----------------'                                                                       || nl ||
                   '    begin'                                                                                  || nl ||
                   '      i := lt_rowid.first;'                                                                 || nl ||
                   '      while (i is not null) loop'                                                           || nl ||
                   '        ft_data(i).r#wid := rowidtochar(lt_rowid(i));'                                      || nl ||
                   '        if (fv_rebind) then'                                                                || nl ||
                   '          pragma inline (select_row_pvt, ''YES'');'                                         || nl ||
                   '          select_row_pvt(fr_data => ft_data(i));'                                           || nl ||
                   '        end if;'                                                                            || nl ||
                   '        i := lt_rowid.next(i);'                                                             || nl ||
                   '      end loop;'                                                                            || nl ||
                   '    exception when others then'                                                             || nl ||
                   '      raise_application_error(-20777, ''<< rowid_bind >>:'' '
                   || ' || $$plsql_line || nl || dbms_utility.format_error_stack);'                             || nl ||
                   '    end rowid_bind;'                                                                        || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end insert_all;'                                                                          || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< insert_all >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end insert_all;
    --------------
    << lock_row >>
    --------------
    begin
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- LOCK_ROW'                                                                              || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure lock_row(fr_id  in RecID)'                                                      || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__    constant varchar2(100) := $$plsql_unit || ''.LOCK_ROW:'';'                      || nl ||
                   '  begin'                                                                                    || nl ||
                   '    inspect_id_pvt(fr_id  => fr_id);'                                                       || nl ||
                   '    lock_row_pvt(fr_id => fr_id);'                                                          || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end lock_row;'                                                                            || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure lock_row(fr_data  in RecData)'                                                  || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__    constant varchar2(100) := $$plsql_unit || ''.LOCK_ROW:'';'                      || nl ||
                   '    lr_id            RecID;'                                                                || nl ||
                   '  begin'                                                                                    || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.pk_element.first;
      while (i is not null) loop
        lv_column := lower(fr_bundle.pk_element(i).column_name);
        lv_buffer := '    lr_id.' || lv_column || ' := fr_data.' || lv_column || ';' || nl;
        put_payload_pvt(lv_buffer);
        i := fr_bundle.pk_element.next(i);
      end loop;
      lv_buffer := '    inspect_id_pvt(fr_id  => lr_id);'                                                       || nl ||
                   '    lock_row_pvt(fr_id => lr_id);'                                                          || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end lock_row;'                                                                            || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< lock_row >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end lock_row;
    --------------
    << lock_all >>
    --------------
    begin
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- LOCK_ALL'                                                                              || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure lock_all(ft_id  in ArrID)'                                                      || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__    constant varchar2(100) := $$plsql_unit || ''.LOCK_ALL:'';'                      || nl ||
                   '    i       pls_integer;'                                                                   || nl ||
                   '  begin'                                                                                    || nl ||
                   '    i := ft_id.first;'                                                                      || nl ||
                   '    while (i is not null) loop'                                                             || nl ||
                   '      pragma inline (lock_row, ''YES'');'                                                   || nl ||
                   '      lock_row(fr_id => ft_id(i));'                                                         || nl ||
                   '      i := ft_id.next(i);'                                                                  || nl ||
                   '    end loop;'                                                                              || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end lock_all;'                                                                            || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure lock_all(ft_data  in ArrData)'                                                  || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__    constant varchar2(100) := $$plsql_unit || ''.LOCK_ALL:'';'                      || nl ||
                   '    i       pls_integer;'                                                                   || nl ||
                   '  begin'                                                                                    || nl ||
                   '    i := ft_data.first;'                                                                    || nl ||
                   '    while (i is not null) loop'                                                             || nl ||
                   '      pragma inline (lock_row, ''YES'');'                                                   || nl ||
                   '      lock_row(fr_data => ft_data(i));'                                                     || nl ||
                   '      i := ft_data.next(i);'                                                                || nl ||
                   '    end loop;'                                                                              || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end lock_all;'                                                                            || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< lock_all >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end lock_all;
    ----------------
    << update_row >>
    ----------------
    begin
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- UPDATE_ROW'                                                                            || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure update_row(fr_data  in out nocopy RecData)'                                     || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__    constant varchar2(100) := $$plsql_unit || ''.UPDATE_ROW:'';'                    || nl ||
                   '  begin'                                                                                    || nl ||
                   '    inspect_data_pvt(fr_data => fr_data);'                                                  || nl ||
                   '    lock_row(fr_data => fr_data);'                                                          || nl ||
                   '    update_row_pvt(fr_data => fr_data);'                                                    || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end update_row;'                                                                          || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< update_row >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end update_row;
    ----------------
    << update_all >>
    ----------------
    begin
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- UPDATE_ALL'                                                                            || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure update_all(ft_data    in out nocopy ArrData,'                                   || nl ||
                   '                       fv_rebind  in boolean default false)'                                || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__    constant varchar2(100) := $$plsql_unit || ''.UPDATE_ALL:'';'                    || nl ||
                   '    lt_rowid         plstring_list;'                                                        || nl ||
                   '    i                pls_integer;'                                                          || nl ||
                   '  begin'                                                                                    || nl ||
                   '    ------------'                                                                           || nl ||
                   '    << sanity >>'                                                                           || nl ||
                   '    ------------'                                                                           || nl ||
                   '    begin'                                                                                  || nl ||
                   '      if (ft_data.count > gc_limit) then'                                                   || nl ||
                   '        raise_application_error(-20888, ''ft_data.count() is limited to '''                 || nl ||
                   '                                        || to_char(gc_limit) || '' elements:'''
                   || ' || $$plsql_line);'                                                                      || nl ||
                   '      end if;'                                                                              || nl ||
                   '      i := ft_data.first;'                                                                  || nl ||
                   '      while (i is not null) loop'                                                           || nl ||
                   '        pragma inline (inspect_data_pvt, ''YES'');'                                         || nl ||
                   '        inspect_data_pvt(fr_data => ft_data(i));'                                           || nl ||
                   '        pragma inline (lock_row, ''YES'');'                                                 || nl ||
                   '        lock_row(fr_data => ft_data(i));'                                                   || nl ||
                   '        i := ft_data.next(i);'                                                              || nl ||
                   '      end loop;'                                                                            || nl ||
                   '    exception when others then'                                                             || nl ||
                   '      raise_application_error(-20777, ''<< sanity >>:'' ||'
                   || ' $$plsql_line || nl || dbms_utility.format_error_stack);'                                || nl ||
                   '    end sanity;'                                                                            || nl ||
                   '    -----------------'                                                                      || nl ||
                   '    << forall_call >>'                                                                      || nl ||
                   '    -----------------'                                                                      || nl ||
                   '    begin'                                                                                  || nl ||
                   '      forall i in indices of ft_data'                                                       || nl ||
                   '      update --+ rowid(a)'                                                                  || nl ||
                   '             ' || lc_table_l || '    a'                                                     || nl ||
                   '         set -- set-list'                                                                   || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.diff_element.first;
      while (i is not null) loop
        lv_colid := lower(fr_bundle.diff_element(i).column_id);
        lv_column := lower(fr_bundle.diff_element(i).column_name);
        lv_rectype := fr_bundle.diff_element(i).record_type;
        lv_ipad := 65 - (2 * lengthb(lv_column));
        lv_buffer := '             a.' || lv_column || ' = ft_data(i).' || lv_column || s# || ppvt(lv_ipad)
                     || ' --' || trim(to_char(lv_colid, '000')) || ' ' || lv_rectype                            || nl;
        if (i != fr_bundle.diff_element.last) then
          lv_buffer := replace(lv_buffer, s#, ',');
        else
          lv_buffer := replace(lv_buffer, s#, ' ');
        end if;
        put_payload_pvt(lv_buffer);
        i := fr_bundle.diff_element.next(i);
      end loop;
      lv_buffer := '       where 1e1 = 1e1'                                                                     || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.pk_element.first;
      while (i is not null) loop
        lv_colid := lower(fr_bundle.pk_element(i).column_id);
        lv_column := lower(fr_bundle.pk_element(i).column_name);
        lv_rectype := fr_bundle.pk_element(i).record_type;
        lv_ipad := 66 - (2 * lengthb(lv_column));
        if (i = fr_bundle.pk_element.first) then
          lv_buffer := '         and a.rowid = ft_data(i).r#wid' || ppvt(57) || '--000 urowid'                  || nl;
        else
          lv_buffer := '         and a.' || lv_column || ' = ft_data(i).' || lv_column || ppvt(lv_ipad)
                       || ' --' || trim(to_char(lv_colid, '000')) || ' ' || lv_rectype                          || nl;
        end if;
        put_payload_pvt(lv_buffer);
        i := fr_bundle.pk_element.next(i);
      end loop;
      lv_buffer := '      returning rowidtochar(rowid) bulk collect into lt_rowid;'                             || nl ||
                   '    exception when others then'                                                             || nl ||
                   '      raise_application_error(-20777, ''<< forall_call >>:'' '
                   || '|| $$plsql_line || nl || dbms_utility.format_error_stack);'                              || nl ||
                   '    end forall_call;'                                                                       || nl ||
                   '    ----------------'                                                                       || nl ||
                   '    << rowid_bind >>'                                                                       || nl ||
                   '    ----------------'                                                                       || nl ||
                   '    begin'                                                                                  || nl ||
                   '      i := lt_rowid.first;'                                                                 || nl ||
                   '      while (i is not null) loop'                                                           || nl ||
                   '        ft_data(i).r#wid := chartorowid(lt_rowid(i));'                                      || nl ||
                   '        if (fv_rebind) then'                                                                || nl ||
                   '          pragma inline (select_row_pvt, ''YES'');'                                         || nl ||
                   '          select_row_pvt(fr_data => ft_data(i));'                                           || nl ||
                   '        end if;'                                                                            || nl ||
                   '        i := lt_rowid.next(i);'                                                             || nl ||
                   '      end loop;'                                                                            || nl ||
                   '    exception when others then'                                                             || nl ||
                   '      raise_application_error(-20777, ''<< rowid_bind >>:'' '
                   || ' || $$plsql_line || nl || dbms_utility.format_error_stack);'                             || nl ||
                   '    end rowid_bind;'                                                                        || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end update_all;'                                                                          || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< update_all >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end update_all;
    ----------------
    << delete_row >>
    ----------------
    begin
      lv_lpad := 4;
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- DELETE_ROW'                                                                            || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure delete_row(fr_id  in RecID)'                                                    || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__    constant varchar2(100) := $$plsql_unit || ''.DELETE_ROW:'';'                    || nl ||
                   '  begin'                                                                                    || nl ||
                   '    lock_row(fr_id => fr_id);'                                                              || nl ||
                   '    delete_row_pvt(fr_id => fr_id);'                                                        || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end delete_row;'                                                                          || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure delete_row(fr_data  in RecData)'                                                || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__    constant varchar2(100) := $$plsql_unit || ''.DELETE_ROW:'';'                    || nl ||
                   '    lr_id            RecID;'                                                                || nl ||
                   '  begin'                                                                                    || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.pk_element.first;
      while (i is not null) loop
        lv_column := lower(fr_bundle.pk_element(i).column_name);
        lv_buffer := '    lr_id.' || lv_column || ' := fr_data.' || lv_column || ';' || nl;
        put_payload_pvt(lv_buffer);
        i := fr_bundle.pk_element.next(i);
      end loop;
      lv_buffer := '    lock_row(fr_id => lr_id);'                                                              || nl ||
                   '    delete_row_pvt(fr_id => lr_id);'                                                        || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end delete_row;'                                                                          || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< delete_row >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end delete_row;
    ----------------
    << delete_all >>
    ----------------
    begin
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- DELETE_ALL'                                                                            || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure delete_all(ft_id  in ArrID)'                                                    || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__    constant varchar2(100) := $$plsql_unit || ''.DELETE_ALL:'';'                    || nl ||
                   '    i                pls_integer;'                                                          || nl ||
                   '  begin'                                                                                    || nl ||
                   '    ------------'                                                                           || nl ||
                   '    << sanity >>'                                                                           || nl ||
                   '    ------------'                                                                           || nl ||
                   '    begin'                                                                                  || nl ||
                   '      if (ft_id.count > gc_limit) then'                                                     || nl ||
                   '        raise_application_error(-20888, ''ft_id.count() is limited to '''                   || nl ||
                   '                                        || to_char(gc_limit) || '' elements:'''
                   || ' || $$plsql_line);'                                                                      || nl ||
                   '      end if;'                                                                              || nl ||
                   '      i := ft_id.first;'                                                                    || nl ||
                   '      while (i is not null) loop'                                                           || nl ||
                   '        pragma inline (lock_row, ''YES'');'                                                 || nl ||
                   '        lock_row(fr_id => ft_id(i));'                                                       || nl ||
                   '        i := ft_id.next(i);'                                                                || nl ||
                   '      end loop;'                                                                            || nl ||
                   '    exception when others then'                                                             || nl ||
                   '      raise_application_error(-20777, ''<< sanity >>:'' ||'
                   || ' $$plsql_line || nl || dbms_utility.format_error_stack);'                                || nl ||
                   '    end sanity;'                                                                            || nl ||
                   '    -----------------'                                                                      || nl ||
                   '    << forall_call >>'                                                                      || nl ||
                   '    -----------------'                                                                      || nl ||
                   '    begin'                                                                                  || nl ||
                   '      forall i in indices of ft_id'                                                         || nl ||
                   '      delete --+ rowid(a)'                                                                  || nl ||
                   '        from ' || lc_table_l || '    a'                                                     || nl ||
                   '       where 1e1 = 1e1'                                                                     || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.pk_element.first;
      while (i is not null) loop
        lv_colid := lower(fr_bundle.pk_element(i).column_id);
        lv_column := lower(fr_bundle.pk_element(i).column_name);
        lv_rectype := fr_bundle.pk_element(i).record_type;
        lv_ipad := 67 - (2 * lengthb(lv_column));
        if (i = fr_bundle.pk_element.first) then
          lv_buffer := '         and a.rowid = ft_id(i).r#wid' || ppvt(59) || '--000 urowid'                    || nl;
        else
          lv_buffer := '         and a.' || lv_column || ' = ft_id(i).' || lv_column || s# || ppvt(lv_ipad)
                       || ' --' || trim(to_char(lv_colid, '000')) || ' ' || lv_rectype                          || nl;
        end if;
        if (i != fr_bundle.pk_element.last) then
          lv_buffer := replace(lv_buffer, s#, ' ');
        else
          lv_buffer := replace(lv_buffer, s#, ';');
        end if;
        put_payload_pvt(lv_buffer);
        i := fr_bundle.pk_element.next(i);
      end loop;
      lv_buffer := '    exception when others then'                                                             || nl ||
                   '      raise_application_error(-20777, ''<< forall_call >>:'' '
                   || '|| $$plsql_line || nl || dbms_utility.format_error_stack);'                              || nl ||
                   '    end forall_call;'                                                                       || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end delete_all;'                                                                          || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure delete_all(ft_data  in ArrData)'                                                || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__    constant varchar2(100) := $$plsql_unit || ''.DELETE_ALL:'';'                    || nl ||
                   '    i                pls_integer;'                                                          || nl ||
                   '  begin'                                                                                    || nl ||
                   '    ------------'                                                                           || nl ||
                   '    << sanity >>'                                                                           || nl ||
                   '    ------------'                                                                           || nl ||
                   '    begin'                                                                                  || nl ||
                   '      if (ft_data.count > gc_limit) then'                                                   || nl ||
                   '        raise_application_error(-20888, ''ft_data.count() is limited to '''                 || nl ||
                   '                                        || to_char(gc_limit) || '' elements:'''
                   || ' || $$plsql_line);'                                                                      || nl ||
                   '      end if;'                                                                              || nl ||
                   '      i := ft_data.first;'                                                                  || nl ||
                   '      while (i is not null) loop'                                                           || nl ||
                   '        pragma inline (lock_row, ''YES'');'                                                 || nl ||
                   '        lock_row(fr_data => ft_data(i));'                                                   || nl ||
                   '        i := ft_data.next(i);'                                                              || nl ||
                   '      end loop;'                                                                            || nl ||
                   '    exception when others then'                                                             || nl ||
                   '      raise_application_error(-20777, ''<< sanity >>:'' ||'
                   || ' $$plsql_line || nl || dbms_utility.format_error_stack);'                                || nl ||
                   '    end sanity;'                                                                            || nl ||
                   '    -----------------'                                                                      || nl ||
                   '    << forall_call >>'                                                                      || nl ||
                   '    -----------------'                                                                      || nl ||
                   '    begin'                                                                                  || nl ||
                   '      forall i in indices of ft_data'                                                       || nl ||
                   '      delete --+ rowid(a)'                                                                  || nl ||
                   '        from ' || lc_table_l || '    a'                                                     || nl ||
                   '       where 1e1 = 1e1'                                                                     || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.pk_element.first;
      while (i is not null) loop
        lv_colid := lower(fr_bundle.pk_element(i).column_id);
        lv_column := lower(fr_bundle.pk_element(i).column_name);
        lv_rectype := fr_bundle.pk_element(i).record_type;
        lv_ipad := 65 - (2 * lengthb(lv_column));
        if (i = fr_bundle.pk_element.first) then
          lv_buffer := '         and a.rowid = ft_data(i).r#wid' || ppvt(57) || '--000 urowid'                  || nl;
        else
          lv_buffer := '         and a.' || lv_column || ' = ft_data(i).' || lv_column || s# || ppvt(lv_ipad)
                       || ' --' || trim(to_char(lv_colid, '000')) || ' ' || lv_rectype                          || nl;
        end if;
        if (i != fr_bundle.pk_element.last) then
          lv_buffer := replace(lv_buffer, s#, ' ');
        else
          lv_buffer := replace(lv_buffer, s#, ';');
        end if;
        put_payload_pvt(lv_buffer);
        i := fr_bundle.pk_element.next(i);
      end loop;
      lv_buffer := '    exception when others then'                                                             || nl ||
                   '      raise_application_error(-20777, ''<< forall_call >>:'' '
                   || '|| $$plsql_line || nl || dbms_utility.format_error_stack);'                              || nl ||
                   '    end forall_call;'                                                                       || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end delete_all;'                                                                          || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< delete_all >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end delete_all;
    ------------------
    << isnull_recid >>
    ------------------
    begin
      lv_lpad := 11;
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- IS_NULL'                                                                               || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  function is_null(fr_id  in RecID)'                                                        || nl ||
                   '    return boolean'                                                                         || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__   constant varchar2(100) := $$plsql_unit || ''.IS_NULL:'';'                        || nl ||
                   '  begin'                                                                                    || nl;
      put_payload_pvt(lv_buffer);
      i := fr_bundle.pk_element.first;
      if (i is not null) then
        lv_largest_cn := largest_colname_pvt(fr_bundle.pk_element);
        i := fr_bundle.pk_element.next(i);    -- skip "R#WID"
        if (i is not null) then
          put_payload_pvt('    return true' || nl);
          while (i is not null) loop
            lv_column := lower(fr_bundle.pk_element(i).column_name);
            lv_ipad := lv_largest_cn - lengthb(lv_column);
            lv_buffer := ppvt(lv_lpad) || 'and fr_id.' || lv_column || ppvt(lv_ipad) || ' is null' || s#        || nl;
            if (i != fr_bundle.pk_element.last) then
              lv_buffer := replace(lv_buffer, s#);
            else
              lv_buffer := replace(lv_buffer, s#, ';');
            end if;
            put_payload_pvt(lv_buffer);
            i := fr_bundle.pk_element.next(i);
          end loop;
        else
          put_payload_pvt('    return true;' || nl);
        end if;
      end if;
      lv_buffer := '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end is_null;'                                                                             || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  function is_null(fr_data  in RecData)'                                                    || nl ||
                   '    return boolean'                                                                         || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__   constant varchar2(100) := $$plsql_unit || ''.IS_NULL:'';'                        || nl ||
                   '  begin'                                                                                    || nl ||
                   '    return true'                                                                            || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< isnull_recid >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end isnull_recid;
    --------------------
    << isnull_recdata >>
    --------------------
    begin
      lv_lpad := 11;
      i := fr_bundle.full_element.first;
      if (i is not null) then
        lv_largest_cn := largest_colname_pvt(fr_bundle.full_element);
        i := fr_bundle.full_element.next(i);    -- skip "R#WID"
        while (i is not null) loop
          lv_column := lower(fr_bundle.full_element(i).column_name);
          lv_ipad := lv_largest_cn - lengthb(lv_column);
          lv_buffer := ppvt(lv_lpad) || 'and fr_data.' || lv_column || ppvt(lv_ipad) || ' is null' || s#        || nl;
          if (i != fr_bundle.full_element.last) then
            lv_buffer := replace(lv_buffer, s#);
          else
            lv_buffer := replace(lv_buffer, s#, ';');
          end if;
          put_payload_pvt(lv_buffer);
          i := fr_bundle.full_element.next(i);
        end loop;
      end if;
      lv_buffer := '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end is_null;'                                                                             || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< isnull_recdata >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end isnull_recdata;
    -------------------
    << isequal_recid >>
    -------------------
    begin
      lv_lpad := 11;
      i := fr_bundle.pk_element.first;
      if (i is not null) then
        lv_buffer := '  ------------------------------------------------------------------'                     || nl ||
                     '  -- IS_EQUAL'                                                                            || nl ||
                     '  ------------------------------------------------------------------'                     || nl ||
                     '  function is_equal(fr_old  in RecID,'                                                    || nl ||
                     '                    fr_new  in RecID)'                                                    || nl ||
                     '    return boolean'                                                                       || nl ||
                     '  is'                                                                                     || nl ||
                     '    lc__   constant varchar2(100) := $$plsql_unit || ''.IS_EQUAL:'';'                     || nl ||
                     '  begin'                                                                                  || nl;
        put_payload_pvt(lv_buffer);
        lv_largest_cn := largest_colname_pvt(fr_bundle.pk_element);
        i := fr_bundle.pk_element.next(i);                                        -- skip "R#WID"
        if (i is not null) then
          put_payload_pvt('    return true' || nl);
          while (i is not null) loop
            lv_column := lower(fr_bundle.pk_element(i).column_name);
            lv_argtype := fr_bundle.pk_element(i).argument_type;
            lv_ipad := lv_largest_cn - lengthb(lv_column);
            lv_buffer := ppvt(lv_lpad)
                         || '-- '        || lv_column || ': ' || lv_argtype                                     || nl ||
                         ppvt(lv_lpad)
                         || 'and ((    fr_old.'        || lv_column || ppvt(lv_ipad)
                         || ' is null and     fr_new.' || lv_column || ppvt(lv_ipad)
                         || ' is null) or '                                                                     || nl ||
                         ppvt(lv_lpad)
                         || '     (not fr_old.'        || lv_column || ppvt(lv_ipad)
                         || ' is null and not fr_new.' || lv_column || ppvt(lv_ipad)
                         || ' is null'                                                                          || nl ||
                         ppvt(lv_lpad)
                         || '      and fr_old.'        || lv_column || ppvt(lv_ipad)
                         || '          =      fr_new.' || lv_column || ppvt(lv_ipad)
                         || '))' || s#                                                                          || nl;
            if (i != fr_bundle.pk_element.last) then
              lv_buffer := replace(lv_buffer, s#);
            else
              lv_buffer := replace(lv_buffer, s#, ';');
            end if;
            put_payload_pvt(lv_buffer);
            i := fr_bundle.pk_element.next(i);
          end loop;
        else
          put_payload_pvt('    return true;' || nl);
        end if;
      end if;
      lv_buffer := '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end is_equal;'                                                                            || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< isequal_recid >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end isequal_recid;
    ---------------------
    << isequal_recdata >>
    ---------------------
    begin
      lv_lpad := 11;
      i := fr_bundle.full_element.first;
      if (i is not null) then
        lv_largest_cn := largest_colname_pvt(fr_bundle.full_element);
        lv_buffer := '  ------------------------------------------------------------------'                     || nl ||
                     '  function is_equal(fr_old  in RecData,'                                                  || nl ||
                     '                    fr_new  in RecData)'                                                  || nl ||
                     '    return boolean'                                                                       || nl ||
                     '  is'                                                                                     || nl ||
                     '    lc__   constant varchar2(100) := $$plsql_unit || ''.IS_EQUAL:'';'                     || nl ||
                     '  begin'                                                                                  || nl ||
                     '    return true'                                                                          || nl;
        put_payload_pvt(lv_buffer);
        i := fr_bundle.full_element.next(i);                                      -- skip 'R#WID'
        while (i is not null) loop
          lv_colid := lower(fr_bundle.full_element(i).column_id);
          lv_column := lower(fr_bundle.full_element(i).column_name);
          lv_argtype := fr_bundle.full_element(i).argument_type;
          lv_ipad := lv_largest_cn - lengthb(lv_column);
          if (fr_bundle.full_element(i).comparable) then
            lv_buffer := ppvt(lv_lpad)
                         || '--' || trim(to_char(lv_colid, '000')) || ' ' || lv_column || ': ' || lv_argtype    || nl ||
                         ppvt(lv_lpad)
                         || 'and ((    fr_old.'        || lv_column || ppvt(lv_ipad)
                         || ' is null and     fr_new.' || lv_column || ppvt(lv_ipad)
                         || ' is null) or '                                                                     || nl ||
                         ppvt(lv_lpad)
                         || '     (not fr_old.'        || lv_column || ppvt(lv_ipad)
                         || ' is null and not fr_new.' || lv_column || ppvt(lv_ipad)
                         || ' is null'                                                                          || nl ||
                         ppvt(lv_lpad);
            if (lv_argtype in ('clob', 'nclob', 'blob')) then
              lv_buffer := lv_buffer
                           || '      and dbms_lob.compare(lob_1  => fr_old.' || lv_column || ','                || nl ||
                           ppvt(lv_lpad)
                           || '                           lob_2  => fr_new.' || lv_column || ','                || nl ||
                           ppvt(lv_lpad)
                           || '                           amount => dbms_lob.lobmaxsize) = 0))'                 || nl;
            elsif (lv_argtype = 'bfile') then
              lv_buffer := lv_buffer
                           || '      and dbms_lob.compare(file_1 => fr_old.' || lv_column || ','                || nl ||
                           ppvt(lv_lpad)
                           || '                           file_2 => fr_new.' || lv_column || ','                || nl ||
                           ppvt(lv_lpad)
                           || '                           amount => dbms_lob.lobmaxsize) = 0))'                 || nl;
            elsif (lv_argtype in ('raw', 'plraw')) then
              lv_buffer := lv_buffer
                           || '      and utl_raw.compare(r1 => fr_old.' || lv_column || ','                     || nl ||
                           ppvt(lv_lpad)
                           || '                          r2 => fr_new.' || lv_column || ') = 0))'               || nl;
            else
              lv_buffer := lv_buffer
                           || '      and fr_old.'        || lv_column || ppvt(lv_ipad)
                           || '          =      fr_new.' || lv_column || ppvt(lv_ipad) || '))'                  || nl;
            end if;
          else
            lv_buffer := ppvt(lv_lpad)
                         || '--'  || trim(to_char(i-1, '000')) || ' '  || lv_column || ': ' || lv_argtype
                         || ' [Type not comparable, skipping...]'                                               || nl;
          end if;
          put_payload_pvt(lv_buffer);
          i := fr_bundle.full_element.next(i);
        end loop;
      end if;
      lv_buffer := '           and true;'                                                                       || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end is_equal;'                                                                            || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< isequal_recdata >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end isequal_recdata;
    --------------------
    << issame_session >>
    --------------------
    begin
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- IS_SAME'                                                                               || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  function is_same(fr_old  in RecID,'                                                       || nl ||
                   '                   fr_new  in RecID)'                                                       || nl ||
                   '    return boolean'                                                                         || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__   constant varchar2(100) := $$plsql_unit || ''.IS_SAME:'';'                        || nl ||
                   '  begin'                                                                                    || nl ||
                   '    pragma inline (is_equal, ''YES'');'                                                     || nl ||
                   '    return (     fr_old.r#wid is not null'                                                  || nl ||
                   '             and fr_new.r#wid is not null'                                                  || nl ||
                   '             and fr_old.r#wid = fr_new.r#wid'                                               || nl ||
                   '           ) and is_equal(fr_old => fr_old,'                                                || nl ||
                   '                          fr_new => fr_new);'                                               || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end is_same;'                                                                             || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  function is_same(fr_old  in RecData,'                                                     || nl ||
                   '                   fr_new  in RecData)'                                                     || nl ||
                   '    return boolean'                                                                         || nl ||
                   '  is'                                                                                       || nl ||
                   '    lc__   constant varchar2(100) := $$plsql_unit || ''.IS_SAME:'';'                        || nl ||
                   '  begin'                                                                                    || nl ||
                   '    pragma inline (is_equal, ''YES'');'                                                     || nl ||
                   '    return (     fr_old.r#wid is not null'                                                  || nl ||
                   '             and fr_new.r#wid is not null'                                                  || nl ||
                   '             and fr_old.r#wid = fr_new.r#wid'                                               || nl ||
                   '           ) and is_equal(fr_old => fr_old,'                                                || nl ||
                   '                          fr_new => fr_new);'                                               || nl ||
                   '  exception when others then'                                                               || nl ||
                   '    raise_application_error(-20777, lc__ || $$plsql_line || nl '
                   || '|| dbms_utility.format_error_stack);'                                                    || nl ||
                   '  end is_same;'                                                                             || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< issame_session >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end issame_session;
    --------------------
    << footer_session >>
    --------------------
    begin
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  --------------------- Initialization Session ---------------------'                       || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   'begin'                                                                                      || nl ||
                   '  $if $$plsql_optimize_level < 3 $then'                                                     || nl ||
                   '    $error $$plsql_unit || '' must be compiled with PLSQL_OPTIMIZE_LEVEL=3'' $end'          || nl ||
                   '  $end'                                                                                     || nl ||
                   '  null;'                                                                                    || nl ||
                   'exception when others then'                                                                 || nl ||
                   '  raise_application_error(-20777, $$plsql_unit || ''<init>:'''
                   || '|| $$plsql_line || nl || dbms_utility.format_error_stack);'                              || nl ||
                   'end ' || lc_api_l || ';'                                                                    || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< footer_session >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end footer_session;
    ---------------------
    << payload_session >>
    ---------------------
    begin
      nksg_tempclob.get_payload(fv_plid    => gv_plid,
                                fv_payload => fv_payload);
    exception when others then
      raise_application_error(-20888, '<< payload_session >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end payload_session;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end implementation_pvt;

  ------------------------------------------------------------------
  -- INTERFACE_PVT
  ------------------------------------------------------------------
  procedure interface_pvt(fr_bundle   in RecBundle,
                          fv_payload  in out nocopy clob)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.INTERFACE_PVT:';
    lc_table_u       constant plstring := upper(fr_bundle.namespace.table_name);
    lc_table_l       constant plstring := lower(fr_bundle.namespace.table_name);
    lc_api_u         constant plstring := upper(fr_bundle.namespace.api_name);
    lc_api_l         constant plstring := lower(fr_bundle.namespace.api_name);
    lv_buffer        plstring;
    lv_column        plstring;
    lv_rectype       plstring;
    lv_flag          plstring;
    lv_lpad          pls_integer;
    lv_ipad          pls_integer;
    lv_largest_cn    pls_integer;
    lv_largest_rt    pls_integer;
    i                pls_integer;
  begin
    ------------------
    << init_session >>
    ------------------
    begin
      reset_pvt;
      new_payload_pvt;
    exception when others then
      raise_application_error(-20888, '<< init_session >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end init_session;
    ---------------------
    << declare_session >>
    ---------------------
    begin
      lv_buffer := 'create or replace package ' || lc_api_l                                                     || nl ||
                   'authid current_user'                                                                        || nl ||
                   'is'                                                                                         || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  -- NKSG: PL/SQL Simple Generator'                                                         || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  --  (c) Copyright 2017 Geraldo Viana (r4vrya@gmail.com)'                                  || nl ||
                   '  --'                                                                                       || nl ||
                   '  --  Licensed under the Apache License, Version 2.0 (the "License"):'                      || nl ||
                   '  --  you may not use this file except in compliance with the License.'                     || nl ||
                   '  --  You may obtain a copy of the License at'                                              || nl ||
                   '  --'                                                                                       || nl ||
                   '  --      http://www.apache.org/licenses/LICENSE-2.0'                                       || nl ||
                   '  --'                                                                                       || nl ||
                   '  --  Unless required by applicable law or agreed to in writing, software'                  || nl ||
                   '  --  distributed under the License is distributed on an "AS IS" BASIS,'                    || nl ||
                   '  --  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.'             || nl ||
                   '  --  See the License for the specific language governing permissions and'                  || nl ||
                   '  --  limitations under the License.'                                                       || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  -- ' || lc_api_u || ': ' || lc_table_u || ' Simple CRUD API'                              || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   ''                                                                                           || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  ------------------------ Declare Session -------------------------'                       || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  -- Inherited types'                                                                       || nl ||
                   '  subtype plstring is varchar2(32767);'                                                     || nl ||
                   '  subtype plraw    is raw(32767);'                                                          || nl ||
                   ''                                                                                           || nl ||
                   '  -- API types'                                                                             || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< declare_session >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end declare_session;
    -------------------
    << recid_session >>
    -------------------
    begin
      i := fr_bundle.pk_element.first;
      if (i is not null) then
        lv_largest_cn := 4 + largest_colname_pvt(fr_bundle.pk_element);
        lv_buffer := '  type RecID is record(';
        put_payload_pvt(lv_buffer);
        while (i is not null) loop
          lv_column := lower(fr_bundle.pk_element(i).column_name);
          lv_rectype := fr_bundle.pk_element(i).record_type;
          lv_ipad := lv_largest_cn - lengthb(lv_column);
          if (i = fr_bundle.pk_element.first) then
            lv_lpad := 0;
          else
            lv_lpad := 23;
          end if;
          lv_buffer := ppvt(lv_lpad) || lv_column || ppvt(lv_ipad) || lv_rectype || s#                          || nl;
          if (i != fr_bundle.pk_element.last) then
            lv_buffer := replace(lv_buffer, s#, ',');
          else
            lv_buffer := replace(lv_buffer, s#, ');');
          end if;
          put_payload_pvt(lv_buffer);
          i := fr_bundle.pk_element.next(i);
        end loop;
        lv_buffer := '  type ArrID is table of RecID index by pls_integer;'                                     || nl ||
                     ''                                                                                         || nl;
        put_payload_pvt(lv_buffer);
      end if;
    exception when others then
      raise_application_error(-20888, '<< recid_session >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end recid_session;
    ---------------------
    << rectype_session >>
    ---------------------
    begin
      i := fr_bundle.full_element.first;
      if (i is not null) then
        lv_largest_cn := 4 + largest_colname_pvt(fr_bundle.full_element);
        lv_largest_rt := 4 + largest_rectype_pvt(fr_bundle.full_element);
        lv_buffer := '  type RecData is record(';
        put_payload_pvt(lv_buffer);
        while (i is not null) loop
          lv_column := lower(fr_bundle.full_element(i).column_name);
          lv_rectype := fr_bundle.full_element(i).record_type;
          lv_flag := fr_bundle.full_element(i).flag;
          if (i = fr_bundle.pk_element.first) then
            lv_lpad := 0;
          else
            lv_lpad := 25;
          end if;
          if (lv_flag is not null) then
            lv_flag := ppvt(lv_largest_rt - lengthb(lv_rectype)) || '-- ' || lv_flag;
          end if;
          lv_buffer := ppvt(lv_lpad) || lv_column || ppvt(lv_largest_cn - lengthb(lv_column))
                       || lv_rectype || s# || lv_flag                                                           || nl;
          if (i != fr_bundle.full_element.last) then
            lv_buffer := replace(lv_buffer, s#, ',');
          else
            lv_buffer := replace(lv_buffer, s#, ');');
          end if;
          put_payload_pvt(lv_buffer);
          i := fr_bundle.full_element.next(i);
        end loop;
      end if;
      lv_buffer := '  type ArrData is table of RecData index by pls_integer;'                                   || nl ||
                   ''                                                                                           || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  ----------------------- Subprogram Session -----------------------'                       || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< rectype_session >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end rectype_session;
    ----------------------------
    << subprogram_dml_session >>
    ----------------------------
    begin
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- EXISTS_ROW'                                                                            || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  function exists_row(fr_id  in RecID)'                                                     || nl ||
                   '    return boolean;'                                                                        || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  function exists_row(fr_data  in RecData)'                                                 || nl ||
                   '    return boolean;'                                                                        || nl ||
                   ''                                                                                           || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  -- SELECT_ROW'                                                                            || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure select_row(fr_data  in out nocopy RecData,'                                     || nl ||
                   '                       fv_lock  in boolean default false);'                                 || nl ||
                   ''                                                                                           || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  -- INSERT_ROW'                                                                            || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure insert_row(fr_data  in out nocopy RecData);'                                    || nl ||
                   ''                                                                                           || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  -- INSERT_ALL'                                                                            || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure insert_all(ft_data    in out nocopy ArrData,'                                   || nl ||
                   '                       fv_rebind  in boolean default false);'                               || nl ||
                   ''                                                                                           || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  -- LOCK_ROW'                                                                              || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure lock_row(fr_id  in RecID);'                                                     || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure lock_row(fr_data  in RecData);'                                                 || nl ||
                   ''                                                                                           || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  -- LOCK_ALL'                                                                              || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure lock_all(ft_id  in ArrID);'                                                     || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure lock_all(ft_data  in ArrData);'                                                 || nl ||
                   ''                                                                                           || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  -- UPDATE_ROW'                                                                            || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure update_row(fr_data  in out nocopy RecData);'                                    || nl ||
                   ''                                                                                           || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  -- UPDATE_ALL'                                                                            || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure update_all(ft_data    in out nocopy ArrData,'                                   || nl ||
                   '                       fv_rebind  in boolean default false);'                               || nl ||
                   ''                                                                                           || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  -- DELETE_ROW'                                                                            || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure delete_row(fr_id  in RecID);'                                                   || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure delete_row(fr_data  in RecData);'                                               || nl ||
                   ''                                                                                           || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  -- DELETE_ALL'                                                                            || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure delete_all(ft_id  in ArrID);'                                                   || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  procedure delete_all(ft_data  in ArrData);'                                               || nl ||
                   ''                                                                                           || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< subprogram_dml_session >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end subprogram_dml_session;
    ----------------------------
    << subprogram_fnc_session >>
    ----------------------------
    begin
      lv_buffer := '  ------------------------------------------------------------------'                       || nl ||
                   '  -- IS_NULL'                                                                               || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  function is_null(fr_id  in RecID)'                                                        || nl ||
                   '    return boolean;'                                                                        || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  function is_null(fr_data  in RecData)'                                                    || nl ||
                   '    return boolean;'                                                                        || nl ||
                   ''                                                                                           || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  -- IS_EQUAL'                                                                              || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  function is_equal(fr_old  in RecID,'                                                      || nl ||
                   '                    fr_new  in RecID)'                                                      || nl ||
                   '    return boolean;'                                                                        || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  function is_equal(fr_old  in RecData,'                                                    || nl ||
                   '                    fr_new  in RecData)'                                                    || nl ||
                   '    return boolean;'                                                                        || nl ||
                   ''                                                                                           || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  -- IS_SAME'                                                                               || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  function is_same(fr_old  in RecID,'                                                       || nl ||
                   '                   fr_new  in RecID)'                                                       || nl ||
                   '    return boolean;'                                                                        || nl ||
                   '  ------------------------------------------------------------------'                       || nl ||
                   '  function is_same(fr_old  in RecData,'                                                     || nl ||
                   '                   fr_new  in RecData)'                                                     || nl ||
                   '    return boolean;'                                                                        || nl ||
                   ''                                                                                           || nl ||
                   'end ' || lc_api_l || ';'                                                                    || nl;
      put_payload_pvt(lv_buffer);
    exception when others then
      raise_application_error(-20888, '<< subprogram_fnc_session >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end subprogram_fnc_session;
    ---------------------
    << payload_session >>
    ---------------------
    begin
      nksg_tempclob.get_payload(fv_plid    => gv_plid,
                                fv_payload => fv_payload);
    exception when others then
      raise_application_error(-20888, '<< payload_session >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
    end payload_session;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end interface_pvt;

  ------------------------------------------------------------------
  -- DML_SPEC_PVT
  ------------------------------------------------------------------
  procedure dml_spec_pvt(fv_table    in varchar2,
                         fv_payload  in out nocopy clob)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.DML_SPEC_PVT:';
    lr_bundle        RecBundle;
  begin
    if (fv_table is null) then
      raise_application_error(-20888, 'fv_table cannot be null:' || $$plsql_line);
    end if;
    fill_bundle_pvt(fv_table  => fv_table,
                    fr_bundle => lr_bundle);
    if (lr_bundle.full_element.count > 0) then
      interface_pvt(fr_bundle  => lr_bundle,
                    fv_payload => fv_payload);
    else
      raise_application_error(-20888, 'Table/Namespace/MetaData not found:' || $$plsql_line);
    end if;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end dml_spec_pvt;

  ------------------------------------------------------------------
  -- DML_BODY_PVT
  ------------------------------------------------------------------
  procedure dml_body_pvt(fv_table    in varchar2,
                         fv_payload  in out nocopy clob)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.DML_BODY_PVT:';
    lr_bundle        RecBundle;
  begin
    if (fv_table is null) then
      raise_application_error(-20888, 'fv_table argument cannot be null:' || $$plsql_line);
    end if;
    fill_bundle_pvt(fv_table  => fv_table,
                    fr_bundle => lr_bundle);
    if (lr_bundle.full_element.count > 0) then
      implementation_pvt(fr_bundle  => lr_bundle,
                         fv_payload => fv_payload);
    else
      raise_application_error(-20888, 'Table/Namespace/MetaData not found:' || $$plsql_line);
    end if;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end dml_body_pvt;

  ------------------------------------------------------------------
  ------------------------- Public Session -------------------------
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  -- DML_SPEC: Generates/Compile Package Specification
  ------------------------------------------------------------------
  function dml_spec(fv_table  in varchar2)
    return clob
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.DML_SPEC:';
    lv_payload       clob;
  begin
    dml_spec_pvt(fv_table   => fv_table,
                 fv_payload => lv_payload);
    if (dbms_lob.getlength(lv_payload) = 0) then
      raise_application_error(-20888, 'DML API Specification payload has zero length:' || $$plsql_line);
    end if;
    return lv_payload;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end dml_spec;
  ------------------------------------------------------------------
  procedure dml_spec(fv_table    in varchar2,
                     fv_replace  in boolean default false)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.DML_SPEC:';
  begin
    if (fv_replace) then
      execute immediate dml_spec(fv_table => fv_table);
    end if;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end dml_spec;

  ------------------------------------------------------------------
  -- DML_BODY: Generates/Compile Package Body
  ------------------------------------------------------------------
  function dml_body(fv_table  in varchar2)
    return clob
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.DML_BODY:';
    lv_payload       clob;
  begin
    dml_body_pvt(fv_table   => fv_table,
                 fv_payload => lv_payload);
    if (dbms_lob.getlength(lv_payload) = 0) then
      raise_application_error(-20888, 'DML API Body payload has zero length:' || $$plsql_line);
    end if;
    return lv_payload;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end dml_body;
  ------------------------------------------------------------------
  procedure dml_body(fv_table    in varchar2,
                     fv_replace  in boolean default false)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.DML_BODY:';
  begin
    if (fv_replace) then
      execute immediate dml_body(fv_table => fv_table);
    end if;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end dml_body;

  ------------------------------------------------------------------
  --------------------- Initialization Session ---------------------
  ------------------------------------------------------------------
begin
  $if $$plsql_optimize_level < 3 $then
    $error $$plsql_unit || ' must be compiled with PLSQL_OPTIMIZE_LEVEL=3' $end
  $end
  null;
exception when others then
  raise_application_error(-20777, $$plsql_unit || '<init>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
end nksg_dmlapi;
