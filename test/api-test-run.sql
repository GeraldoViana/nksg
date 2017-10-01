------------------------------------------------------------------------------------------------------------------------
-- NKSG: PL/SQL Simple Generator
------------------------------------------------------------------------------------------------------------------------
-- @api-test-run.sql: Create dummy table with arbitrary columns, run the generator, populate/modify/purge data using API.
------------------------------------------------------------------------------------------------------------------------
set echo off
prompt +-------------------------------------------------------------------------+
prompt | NKSG: PL/SQL Simple Generator                                           |
prompt +-------------------------------------------------------------------------+
prompt | (c) Copyright 2017 Geraldo Viana (r4vrya@gmail.com)                     |
prompt |                                                                         |
prompt | Licensed under the Apache License, Version 2.0 (the "License"):         |
prompt | you may not use this file except in compliance with the License.        |
prompt | You may obtain a copy of the License at                                 |
prompt |                                                                         |
prompt |     http://www.apache.org/licenses/LICENSE-2.0                          |
prompt |                                                                         |
prompt | Unless required by applicable law or agreed to in writing, software     |
prompt | distributed under the License is distributed on an "AS IS" BASIS,       |
prompt | WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.|
prompt | See the License for the specific language governing permissions and     |
prompt | limitations under the License.                                          |
prompt +-------------------------------------------------------------------------+
prompt | SQL> @api-test-run.sql                                                  |
prompt +-------------------------------------------------------------------------+
whenever sqlerror continue
whenever oserror  continue
set define off
set feedback on
set heading off
set linesize 120
set loboffset 1
set long 16777216
set longchunksize 8192
set pause off
set scan on
set serveroutput on size 1000000
set sqlblanklines on
set tab off
set termout on
set timing off
set trimspool off
set verify off
set wrap on

prompt +-------------------------------------------------------------------------+
prompt | Cleaning up any previous runs ...                                       |
prompt +-------------------------------------------------------------------------+
drop table   nksg_apitest;
drop package nksg_apitest_dml;

prompt +-------------------------------------------------------------------------+
prompt | Setting PL/SQL compiler flags ...                                       |
prompt +-------------------------------------------------------------------------+
alter session set plsql_warnings='enable:all,disable:05005,disable:06002,disable:06004,disable:06005,disable:06006,disable:06010,disable:07202,disable:07204,disable:07206';
alter session set plsql_optimize_level=3;
alter session set plsql_code_type=native;
alter session set plscope_settings='identifiers:none';

prompt +-------------------------------------------------------------------------+
prompt | Creating table: NKSG_APITEST ...                                        |
prompt +-------------------------------------------------------------------------+
create table nksg_apitest (
  id                             number(16)           not null enable,    -- 01/25
  number_column                  number(14,-2)        not null enable,    -- 02/25
  float_column                   float(11)            not null enable,    -- 03/25
  char_column                    char(7 byte)         not null enable,    -- 04/25
  flag                           varchar2(1)          not null enable,    -- 05/25
  binary_float_column            binary_float,                            -- 06/25
  binary_double_column           binary_double,                           -- 07/25
  rowid_column                   rowid,                                   -- 08/25
  urowid_column                  urowid,                                  -- 09/25
  nchar_column                   nchar(25),                               -- 10/25
  varchar2_column                varchar2(150 char),                      -- 11/25
  nvarchar2_column               nvarchar2(150),                          -- 12/25
  date_column                    date,                                    -- 13/25
  timestamp_column               timestamp(9),                            -- 14/25
  timestampwtz_column            timestamp(9) with time zone,             -- 15/25
  timestampwltz_column           timestamp(9) with local time zone,       -- 16/25
  intervalytm_column             interval year(9) to month,               -- 17/25
  intervaldts_column             interval day(9) to second(9),            -- 18/25
  raw_column                     raw(70),                                 -- 19/25
  clob_column                    clob,                                    -- 20/25
  nclob_column                   nclob,                                   -- 21/25
  blob_column                    blob,                                    -- 22/25
  bfile_column                   bfile,                                   -- 23/25
  xmltype_column                 xmltype,                                 -- 24/25
  max_length_name_for_a_column_z number(1)                                -- 25/25
);

create unique index nksg_apitest                                    -- Same name as table but in different namespace
  on nksg_apitest(id);

create unique index nksg_apitest_u1
  on nksg_apitest(number_column, flag, date_column, nchar_column);

alter table nksg_apitest
  add constraint nksg_apitest                                       -- Same name as table but in different namespace
  primary key (id) using index enable;

alter table nksg_apitest
  add constraint nksg_apitest_u1
  unique (number_column, flag, date_column, nchar_column) using index enable;

alter table nksg_apitest add constraint nksg_apitest_ck1 check (flag in ('X','Y','Z'));

alter table nksg_apitest add constraint nksg_apitest_ck2 check (char_column = upper(char_column));

prompt +-------------------------------------------------------------------------+
prompt | Creating trigger: NKSG_APITEST ...                                      |
prompt +-------------------------------------------------------------------------+
prompt | The trigger serves to test returning data through the API               |
prompt +-------------------------------------------------------------------------+
create or replace trigger nksg_apitest                              -- Same name as table but in different namespace
for insert or update or delete on nksg_apitest
compound trigger
  ------------------------------------------------------------------
  ------------------------ Declare Session -------------------------
  ------------------------------------------------------------------
  nl     constant varchar2(3) := '
';
  lv_row#         integer;

  ------------------------------------------------------------------
  -- BEFORE STATEMENT
  ------------------------------------------------------------------
  before statement
  is
    lc__    constant varchar2(100) := 'Trigger ' || $$plsql_unit || '[Before Statement]:';
  begin
    lv_row# := 0;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end before statement;

  ------------------------------------------------------------------
  -- BEFORE EACH ROW
  ------------------------------------------------------------------
  before each row
  is
    lc__    constant varchar2(100) := 'Trigger ' || $$plsql_unit || '[Before Each Row]:';
    lc_javamagics    constant clob := '0' || rpad('cafebabe', 32767, 'cafebabe')
                                          || rpad('cafebabe', 32767, 'cafebabe');    -- 65535 bytes
  begin
    if (inserting or updating) then
      if (mod(:new.id, 2) != 0) then
        :new.id := :new.id + 1;
        --raise_application_error(-20888, 'Sorry, only even numbers allowed in primary key:' || $$plsql_line);
      end if;
      :new.number_column := :new.number_column / 2;
      :new.float_column := :new.float_column * 2;
      :new.char_column := 'BEOWULF';
      :new.flag := case :new.flag when 'X' then 'Y' when 'Y' then 'X' else 'Z' end;
      :new.varchar2_column := translate(:new.varchar2_column, 'Aa', 'Zz');
      :new.nvarchar2_column := unistr('\20ac');                  -- Euro symbol
      :new.date_column := to_date(2455027, 'j') + 1-(1e-5);      -- '2009-07-14 23:59:59', 'YYYY-MM-DD HH24:MI:SS'
      :new.clob_column := lc_javamagics;
    end if;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end before each row;

  ------------------------------------------------------------------
  -- AFTER EACH ROW
  ------------------------------------------------------------------
  after each row
  is
    lc__    constant varchar2(100) := 'Trigger ' || $$plsql_unit || '[After Each Row]:';
  begin
    lv_row# := lv_row# + 1;
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end after each row;

  ------------------------------------------------------------------
  -- AFTER STATEMENT
  ------------------------------------------------------------------
  after statement
  is
    lc__    constant varchar2(100) := 'Trigger ' || $$plsql_unit || '[After Statement]:';
  begin
    dbms_output.put_line(lc__ ||  ' ' || to_char(lv_row#) || ' row(s) processed');
  exception when others then
    raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end after statement;

end nksg_apitest;
/
show errors

prompt +-------------------------------------------------------------------------+
prompt | Generating CRUD API for Table: NKSG_APITEST ...                         |
prompt +-------------------------------------------------------------------------+
prompt | This call generates/compile both the API Package Specification          |
prompt | and Package Body                                                        |
prompt +-------------------------------------------------------------------------+
declare
  lc__        constant varchar2(100) := 'Anonymous PL/SQL Block:';
  lc_table    constant varchar2(30) := 'NKSG_APITEST';
  nl          constant varchar2(3) := '
';
begin
  --------------
  << dml_spec >>
  --------------
  begin
    nksg_dmlapi.dml_spec(fv_table   => lc_table,
                         fv_replace => true);    -- CAUTION: It will override any customization done previously
  exception when others then
    raise_application_error(-20888, '<< dml_spec >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
  end dml_spec;
  --------------
  << dml_body >>
  --------------
  begin
    nksg_dmlapi.dml_body(fv_table   => lc_table,
                         fv_replace => true);    -- CAUTION: It will override any customization done previously
  exception when others then
    raise_application_error(-20888, '<< dml_body >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
  end dml_body;
exception when others then
  raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
end main;
/

prompt +-------------------------------------------------------------------------+
prompt | Binding data and call nksg_apitest_dml.insert_row()                     |
prompt +-------------------------------------------------------------------------+
declare
  lc__       constant varchar2(100) := 'Anonymous PL/SQL Block:';
  nl         constant varchar2(3) := '
';
  lr_data    nksg_apitest_dml.RecData;
begin
  -- trigger will set to: -50
  lr_data.id := -51;                                                                -- 01/25 number(16)           not null enable,
  -- sql% will set to: 184500
  lr_data.number_column := 184522.99999;                                            -- 02/25 number(14,-2)        not null enable,
  lr_data.float_column := 7f;                                                       -- 03/25 float(11)            not null enable,
  lr_data.char_column := 'XXXXX';                                                   -- 04/25 char(7 byte)         not null enable,
  lr_data.flag := 'Z';                                                              -- 05/25 varchar2(1)          not null enable,
  -- trigger will set to: 'Zbrzczdzbrz'
  lr_data.varchar2_column := 'Abracadabra';                                         -- 11/25 varchar2(150 char),
  -- trigger will set to: '€'
  lr_data.nvarchar2_column := '3';                                                  -- 12/25 nvarchar2(150),
  -- trigger will set to: '2009-07-14 23:59:59'
  lr_data.date_column := to_date('2017-10-01 00:05:14', 'YYYY-MM-DD HH24:MI:SS');   -- 13/25 date,
  -- trigger will set to: 65535 bytes
  lr_data.clob_column := '0x';                                                      -- 20/25 clob,
  dbms_output.put_line('Data before NKSG_APITEST_DML.INSERT_ROW() call');
  dbms_output.put_line('-----------------------------------------------');
  dbms_output.put_line('lr_data.id                  = ' || lr_data.id);
  dbms_output.put_line('lr_data.number_column       = ' || to_char(lr_data.number_column));
  dbms_output.put_line('lr_data.float_column        = ' || to_char(lr_data.float_column));
  dbms_output.put_line('lr_data.char_column         = ' || lr_data.char_column);
  dbms_output.put_line('lr_data.flag                = ' || lr_data.flag);
  dbms_output.put_line('lr_data.varchar2_column     = ' || lr_data.varchar2_column);
  dbms_output.put_line('lr_data.nvarchar2_column    = ' || lr_data.nvarchar2_column);
  dbms_output.put_line('lr_data.date_column         = ' || to_char(lr_data.date_column, 'yyyy-mm-dd hh24:mi:ss'));
  dbms_output.put_line('lr_data.clob_column(length) = ' || dbms_lob.getlength(lob_loc => lr_data.clob_column));
  dbms_output.put_line('-----------------------------------------------');
  dbms_output.put_line('NKSG_APITEST_DML.INSERT_ROW() call');
  dbms_output.put_line('-----------------------------------------------');
  nksg_apitest_dml.insert_row(fr_data => lr_data);
  dbms_output.put_line('-----------------------------------------------');
  dbms_output.put_line('Data after NKSG_APITEST_DML.INSERT_ROW() call');
  dbms_output.put_line('-----------------------------------------------');
  dbms_output.put_line('lr_data.id                  = ' || lr_data.id);
  dbms_output.put_line('lr_data.number_column       = ' || to_char(lr_data.number_column));
  dbms_output.put_line('lr_data.float_column        = ' || to_char(lr_data.float_column));
  dbms_output.put_line('lr_data.char_column         = ' || lr_data.char_column);
  dbms_output.put_line('lr_data.flag                = ' || lr_data.flag);
  dbms_output.put_line('lr_data.varchar2_column     = ' || lr_data.varchar2_column);
  dbms_output.put_line('lr_data.nvarchar2_column    = ' || lr_data.nvarchar2_column);
  dbms_output.put_line('lr_data.date_column         = ' || to_char(lr_data.date_column, 'yyyy-mm-dd hh24:mi:ss'));
  dbms_output.put_line('lr_data.clob_column(length) = ' || dbms_lob.getlength(lob_loc => lr_data.clob_column));
  dbms_output.put_line('-----------------------------------------------');
exception when others then
  raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
end main;
/

prompt +-------------------------------------------------------------------------+
prompt | Disabling trigger NKSG_APITEST                                          |
prompt +-------------------------------------------------------------------------+
alter trigger nksg_apitest disable;

prompt +-------------------------------------------------------------------------+
prompt | Binding data and call nksg_apitest_dml.update_row()                     |
prompt +-------------------------------------------------------------------------+
declare
  lc__       constant varchar2(100) := 'Anonymous PL/SQL Block:';
  nl         constant varchar2(3) := '
';
  lr_data    nksg_apitest_dml.RecData;
begin
  -- trigger will set to: -50
  lr_data.id := -51;                                                                -- 01/25 number(16)           not null enable,
  -- sql% will set to: 184500
  lr_data.number_column := 184522.99999;                                            -- 02/25 number(14,-2)        not null enable,
  lr_data.float_column := 7f;                                                       -- 03/25 float(11)            not null enable,
  lr_data.char_column := 'XXXXX';                                                   -- 04/25 char(7 byte)         not null enable,
  lr_data.flag := 'Z';                                                              -- 05/25 varchar2(1)          not null enable,
  -- trigger will set to: 'Zbrzczdzbrz'
  lr_data.varchar2_column := 'Abracadabra';                                         -- 11/25 varchar2(150 char),
  -- trigger will set to: '€'
  lr_data.nvarchar2_column := '3';                                                  -- 12/25 nvarchar2(150),
  -- trigger will set to: '2009-07-14 23:59:59'
  lr_data.date_column := to_date('2017-10-01 00:05:14', 'YYYY-MM-DD HH24:MI:SS');   -- 13/25 date,
  -- trigger will set to: 65535 bytes
  lr_data.clob_column := '0x';                                                      -- 20/25 clob,
  dbms_output.put_line('Data before NKSG_APITEST_DML.UPDATE_ROW() call');
  dbms_output.put_line('-----------------------------------------------');
  dbms_output.put_line('lr_data.id                  = ' || lr_data.id);
  dbms_output.put_line('lr_data.number_column       = ' || to_char(lr_data.number_column));
  dbms_output.put_line('lr_data.float_column        = ' || to_char(lr_data.float_column));
  dbms_output.put_line('lr_data.char_column         = ' || lr_data.char_column);
  dbms_output.put_line('lr_data.flag                = ' || lr_data.flag);
  dbms_output.put_line('lr_data.varchar2_column     = ' || lr_data.varchar2_column);
  dbms_output.put_line('lr_data.nvarchar2_column    = ' || lr_data.nvarchar2_column);
  dbms_output.put_line('lr_data.date_column         = ' || to_char(lr_data.date_column, 'yyyy-mm-dd hh24:mi:ss'));
  dbms_output.put_line('lr_data.clob_column(length) = ' || dbms_lob.getlength(lob_loc => lr_data.clob_column));
  dbms_output.put_line('-----------------------------------------------');
  dbms_output.put_line('NKSG_APITEST_DML.UPDATE_ROW() call');
  dbms_output.put_line('-----------------------------------------------');
  nksg_apitest_dml.update_row(fr_data => lr_data);
  dbms_output.put_line('-----------------------------------------------');
  dbms_output.put_line('Data after NKSG_APITEST_DML.UPDATE_ROW() call');
  dbms_output.put_line('-----------------------------------------------');
  dbms_output.put_line('lr_data.id                  = ' || lr_data.id);
  dbms_output.put_line('lr_data.number_column       = ' || to_char(lr_data.number_column));
  dbms_output.put_line('lr_data.float_column        = ' || to_char(lr_data.float_column));
  dbms_output.put_line('lr_data.char_column         = ' || lr_data.char_column);
  dbms_output.put_line('lr_data.flag                = ' || lr_data.flag);
  dbms_output.put_line('lr_data.varchar2_column     = ' || lr_data.varchar2_column);
  dbms_output.put_line('lr_data.nvarchar2_column    = ' || lr_data.nvarchar2_column);
  dbms_output.put_line('lr_data.date_column         = ' || to_char(lr_data.date_column, 'yyyy-mm-dd hh24:mi:ss'));
  dbms_output.put_line('lr_data.clob_column(length) = ' || dbms_lob.getlength(lob_loc => lr_data.clob_column));
  dbms_output.put_line('-----------------------------------------------');
exception when others then
  raise_application_error(-20777, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
end main;
/

prompt +-------------------------------------------------------------------------+
prompt | EOS: End of script                                                      |
prompt +-------------------------------------------------------------------------+
set feedback on
set heading on
set echo off
