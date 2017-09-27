------------------------------------------------------------------------------------------------------------------------
-- @nksg-install.sql: Install "NKSG: PL/SQL Simple Generator" in the schema running this script
------------------------------------------------------------------------------------------------------------------------
-- You can create an specific user/owner/schema with the script: nksg-schema.sql
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
prompt | SQL> @nksg-install.sql                                                  |
prompt +-------------------------------------------------------------------------+
whenever sqlerror continue
whenever oserror  continue
set define off
set feedback off
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
prompt | NKSG: Start of script                                                   |
prompt +-------------------------------------------------------------------------+

set echo on
alter session set plsql_warnings='enable:all,disable:05005,disable:06002,disable:06004,disable:06005,disable:06006,disable:07206';
alter session set plsql_optimize_level=3;
alter session set plsql_code_type=native;
alter session set plscope_settings='identifiers:none';

set echo off
prompt +-------------------------------------------------------------------------+
prompt | NKSG: Creating Package Specification                                    |
prompt +-------------------------------------------------------------------------+

prompt Creating Package: NKSG_TEMPCLOB ...
@@nksg_tempclob.pks
/
show errors

prompt Creating Package: NKSG_DMLAPI ...
@@nksg_dmlapi.pks
/
show errors

prompt +-------------------------------------------------------------------------+
prompt | NKSG: Creating Package Implementation                                   |
prompt +-------------------------------------------------------------------------+

prompt Creating Package Body: NKSG_TEMPCLOB ...
@@nksg_tempclob.pkb
/
show errors

prompt Creating Package Body: NKSG_DMLAPI ...
@@nksg_dmlapi.pkb
/
show errors

prompt +-------------------------------------------------------------------------+
prompt | NKSG: End of Script                                                     |
prompt +-------------------------------------------------------------------------+
set feedback on
set heading on
set echo off
