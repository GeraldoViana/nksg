------------------------------------------------------------------------------------------------------------------------
-- @nksg-uninstall.sql: Deinstall "NKSG: PL/SQL Simple Generator" in the schema running this script
------------------------------------------------------------------------------------------------------------------------
-- FYI: To prevent accidental running this script, comment out or remove the two lines below...
prompt aborting nksg-uninstall.sql execution ...
quit failure;
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
prompt | SQL> @nksg-uninstall.sql                                                |
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

prompt +-------------------------------------------------------------------------+
prompt | NKSG: Dropping Package Implementation                                   |
prompt +-------------------------------------------------------------------------+

prompt Dropping Package Body: NKSG_DMLAPI ...
drop package body nksg_dmlapi;

prompt Dropping Package Body: NKSG_TEMPCLOB ...
drop package body nksg_tempclob;

prompt +-------------------------------------------------------------------------+
prompt | NKSG: Dropping Package Specification                                    |
prompt +-------------------------------------------------------------------------+

prompt Dropping Package: NKSG_DMLAPI ...
drop package nksg_dmlapi;

prompt Dropping Package: NKSG_TEMPCLOB ...
drop package nksg_tempclob;

prompt +-------------------------------------------------------------------------+
prompt | NKSG: End of Script                                                     |
prompt +-------------------------------------------------------------------------+
set feedback on
set heading on
set echo off
