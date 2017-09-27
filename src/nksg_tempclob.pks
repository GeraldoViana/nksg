create or replace package nksg_tempclob
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
  -- NKSG_TEMPCLOB: Temporary CLOBs with simpler API
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  ------------------------ Declare Session -------------------------
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  ----------------------- Subprogram Session -----------------------
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  -- NEW_PAYLOAD - Creates a new temporary CLOB
  ------------------------------------------------------------------
  function new_payload
    return pls_integer;

  ------------------------------------------------------------------
  -- PAYLOAD_LENGTH - Returns the temporary CLOB length
  ------------------------------------------------------------------
  function payload_length(fv_plid  in pls_integer)
    return integer;

  ------------------------------------------------------------------
  -- PUT_PAYLOAD - Put data to a temporary CLOB
  ------------------------------------------------------------------
  procedure put_payload(fv_plid  in pls_integer,
                        fv_data  in varchar2);
  ------------------------------------------------------------------
  procedure put_payload(fv_plid  in pls_integer,
                        fv_clob  in clob);

  ------------------------------------------------------------------
  -- GET_PAYLOAD - Retrieve payload
  ------------------------------------------------------------------
  procedure get_payload(fv_plid     in pls_integer,
                        fv_payload  in out nocopy clob);
  ------------------------------------------------------------------
  procedure get_payload(fv_plid     in pls_integer,
                        fv_csid     in integer default dbms_lob.default_csid,
                        fv_lang     in integer default dbms_lob.default_lang_ctx,
                        fv_payload  in out nocopy blob);

  ------------------------------------------------------------------
  -- FREE - Drops the buffer and free resources
  ------------------------------------------------------------------
  procedure free(fv_plid  in pls_integer);

  ------------------------------------------------------------------
  -- FREE_ALL - Drops all buffers in use for this session
  ------------------------------------------------------------------
  procedure free_all;

end nksg_tempclob;
