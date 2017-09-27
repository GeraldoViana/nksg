create or replace package nksg_dmlapi
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
  -- NKSG_DMLAPI: Generates Simple CRUD API
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  ------------------------ Declare Session -------------------------
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  ----------------------- Subprogram Session -----------------------
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  -- DML_SPEC: Generates/Compile Package Specification
  ------------------------------------------------------------------
  function dml_spec(fv_table  in varchar2)
    return clob;
  ------------------------------------------------------------------
  procedure dml_spec(fv_table    in varchar2,
                     fv_replace  in boolean default false);

  ------------------------------------------------------------------
  -- DML_BODY: Generates/Compile Package Body
  ------------------------------------------------------------------
  function dml_body(fv_table  in varchar2)
    return clob;
  ------------------------------------------------------------------
  procedure dml_body(fv_table    in varchar2,
                     fv_replace  in boolean default false);

end nksg_dmlapi;
