create or replace package body nksg_tempclob
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
  -- Local constants
  nl    constant varchar2(3) := '
';

  -- plsql
  gc_plstringub     constant pls_integer := 32767; -- PLSQL varchar2 upper bound
  gc_plrawub        constant pls_integer := 32767; -- PLSQL raw upper bound
  gc_sqlstringub    constant pls_integer := 4000;  -- SQL varchar2 upper bound
  gc_sqlrawub       constant pls_integer := 2000;  -- SQL raw upper bound
  subtype plstring  is varchar2(32767); -- keep same as gc_plstringub
  subtype plraw     is raw(32767);      -- keep same as gc_plrawub
  subtype sqlstring is varchar2(4000);  -- keep same as gc_sqlstringub
  subtype sqlraw    is raw(2000);       -- keep same as gc_sqlrawub

  -- Self types
  type RecPayload is record(buffer   plstring,
                            payload  clob);
  type ArrPayload is table of RecPayload index by pls_integer;

  -- Containers
  gv_index    integer := 1;
  gt_payload  ArrPaylod;

  ------------------------------------------------------------------
  ------------------------ Private Session -------------------------
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  -- FLUSH_PVT
  ------------------------------------------------------------------
  procedure flush_pvt(fv_plid  in pls_integer)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.FLUSH_PVT:';
  begin
    if (gt_payload(fv_plid).buffer is not null) then
      dbms_lob.writeappend(lob_loc => gt_payload(fv_plid).payload,
                           amount  => lengthb(gt_payload(fv_plid).buffer),
                           buffer  => gt_payload(fv_plid).buffer);
      gt_payload(fv_plid).buffer := null;
    end if;
  exception when others then
    raise_application_error(-20904, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end flush_pvt;

  ------------------------------------------------------------------
  -- PUT_PAYLOAD_PVT
  ------------------------------------------------------------------
  procedure put_payload_pvt(fv_plid  in pls_integer,
                            fv_data  in varchar2)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.PUT_PAYLOAD_PVT:';
  begin
    if (fv_data is not null) then
      if (nvl(lengthb(gt_payload(fv_plid).buffer),0) + nvl(lengthb(fv_data),0) <= gc_plstringub) then
        gt_payload(fv_plid).buffer := gt_payload(fv_plid).buffer || fv_data;
      else
        flush_pvt(fv_plid => fv_plid);
        gt_payload(fv_plid).buffer := fv_data;
      end if;
    end if;
  exception when others then
    raise_application_error(-20904, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end put_payload_pvt;

  ------------------------------------------------------------------
  ------------------------- Public Session -------------------------
  ------------------------------------------------------------------

  ------------------------------------------------------------------
  -- NEW_PAYLOAD - Creates a new temporary CLOB
  ------------------------------------------------------------------
  function new_payload
    return pls_integer
  is
    lc__   constant varchar2(100) := $$plsql_unit || '.NEW_PAYLOAD:';
    lv_plid         pls_integer;
  begin
    lv_plid := gv_index;
    gv_index := gv_index + 1;
    gt_payload(lv_plid).payload := empty_clob;
    dbms_lob.createtemporary(lob_loc => gt_payload(lv_plid).payload,
                             cache   => true,
                             dur     => dbms_lob.session);
    if (not dbms_lob.isopen(lob_loc => gt_payload(lv_plid).payload) = 1) then
      dbms_lob.open(lob_loc   => gt_payload(lv_plid).payload,
                    open_mode => dbms_lob.lob_readwrite);
    end if;
    return lv_plid;
  exception when others then
    raise_application_error(-20904, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end new_payload;

  ------------------------------------------------------------------
  -- PAYLOAD_LENGTH - Returns the temporary CLOB length
  ------------------------------------------------------------------
  function payload_length(fv_plid  in pls_integer)
    return integer
  is
    lc__       constant varchar2(100) := $$plsql_unit || '.PAYLOAD_LENGTH:';
    lv_result  integer;
  begin
    if (fv_plid is not null and gt_payload.exists(fv_plid)) then
      lv_result := dbms_lob.getlength(gt_payload(fv_plid).payload) +
                   lengthb(gt_payload(fv_plid).buffer);
    end if;
    return lv_result;
  exception when others then
    raise_application_error(-20904, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end payload_length;

  ------------------------------------------------------------------
  -- PUT_PAYLOAD - Put data to a temporary CLOB
  ------------------------------------------------------------------
  procedure put_payload(fv_plid  in pls_integer,
                        fv_data  in varchar2)
  is
    lc__  constant varchar2(100) := $$plsql_unit || '.PUT_PAYLOAD:';
  begin
    if (not gt_payload.exists(fv_plid)) then
      raise_application_error(-20999, 'Invalid payload handler:' || $$plsql_line);
    elsif (fv_data is not null) then
      pragma inline (put_payload_pvt, 'YES');
      put_payload_pvt(fv_plid => fv_plid,
                      fv_data => fv_data);
    end if;
  exception when others then
    raise_application_error(-20904, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end put_payload;
  ------------------------------------------------------------------
  procedure put_payload(fv_plid  in pls_integer,
                        fv_clob  in clob)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.PUT_PAYLOAD:';
    lv_amount        integer := gc_plstringub;
    lv_offset        integer := 1;
    lv_buffer        plstring;
  begin
    if (not gt_payload.exists(fv_plid)) then
      raise_application_error(-20999, 'Invalid payload handler:' || $$plsql_line);
    elsif (fv_clob is not null) then
      -------------
      << lobloop >>
      -------------
      loop
        begin
          dbms_lob.read(lob_loc  => fv_clob,
                        amount   => lv_amount,
                        offset   => lv_offset,
                        buffer   => lv_buffer);
          lv_offset := lv_offset + lv_amount;
          if (lv_buffer is not null) then
            pragma inline (put_payload_pvt, 'YES');
            put_payload_pvt(fv_plid => fv_plid,
                            fv_data => lv_buffer);
          end if;
        exception
          when no_data_found then
            exit lobloop;
          when others then
            raise_application_error(-20904, '<< lobloop >>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
        end;
      end loop lobloop;
    end if;
  exception when others then
    raise_application_error(-20904, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end put_payload;

  ------------------------------------------------------------------
  -- GET_PAYLOAD - Retrieve payload
  ------------------------------------------------------------------
  procedure get_payload(fv_plid     in pls_integer,
                        fv_payload  in out nocopy clob)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.GET_PAYLOAD:';
  begin
    if (fv_plid is not null and gt_payload.exists(fv_plid)) then
      flush_pvt(fv_plid => fv_plid);
      fv_payload := gt_payload(fv_plid).payload;
    end if;
  exception when others then
    raise_application_error(-20904, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end get_payload;
  ------------------------------------------------------------------
  procedure get_payload(fv_plid     in pls_integer,
                        fv_csid     in integer default dbms_lob.default_csid,
                        fv_lang     in integer default dbms_lob.default_lang_ctx,
                        fv_payload  in out nocopy blob)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.GET_PAYLOAD:';
    lv_source_offset integer := 1;
    lv_target_offset integer := 1;
    lv_csid          number := fv_csid;
    lv_lang          integer := fv_lang;
    lv_warning       integer;
  begin
    if (fv_plid is not null) then
      flush_pvt(fv_plid => fv_plid);
      if (gt_payload(fv_plid).payload is not null and dbms_lob.getlength(gt_payload(fv_plid).payload) > 0) then
        if (fv_payload is null) then
          dbms_lob.createtemporary(lob_loc => fv_payload,
                                   cache   => true,
                                   dur     => dbms_lob.session);
          if (not dbms_lob.isopen(lob_loc => fv_payload) = 1) then
            dbms_lob.open(lob_loc   => fv_payload,
                          open_mode => dbms_lob.lob_readwrite);
          end if;
        end if;
        dbms_lob.converttoblob(dest_lob     => fv_payload,
                               src_clob     => gt_payload(fv_plid).payload,
                               amount       => dbms_lob.getlength(gt_payload(fv_plid).payload),
                               dest_offset  => lv_target_offset,
                               src_offset   => lv_source_offset,
                               blob_csid    => lv_csid,
                               lang_context => lv_lang,
                               warning      => lv_warning);
      end if;
    end if;
  exception when others then
    raise_application_error(-20904, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end get_payload;

  ------------------------------------------------------------------
  -- FREE - Drops the buffer and free resources
  ------------------------------------------------------------------
  procedure free(fv_plid  in pls_integer)
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.FREE:';
  begin
    if (fv_plid is not null and gt_payload.exists(fv_plid)) then
      if (dbms_lob.isopen(lob_loc => gt_payload(fv_plid).payload) = 1) then
        dbms_lob.close(lob_loc => gt_payload(fv_plid).payload);
      end if;
      dbms_lob.freetemporary(lob_loc => gt_payload(fv_plid).payload);
      gt_payload.delete(fv_plid);
    end if;
  exception when others then
    raise_application_error(-20904, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end free;

  ------------------------------------------------------------------
  -- FREE_ALL - Drops all buffers in use for this session
  ------------------------------------------------------------------
  procedure free_all
  is
    lc__    constant varchar2(100) := $$plsql_unit || '.FREE_ALL:';
    i       pls_integer := gt_payload.first;
  begin
    while (i is not null) loop
      if (dbms_lob.isopen(lob_loc => gt_payload(i).payload) = 1) then
        dbms_lob.close(lob_loc => gt_payload(i).payload);
      end if;
      dbms_lob.freetemporary(lob_loc => gt_payload(i).payload);
      i := gt_payload.next(i);
    end loop;
    gt_payload.delete;
  exception when others then
    raise_application_error(-20904, lc__ || $$plsql_line || nl || dbms_utility.format_error_stack);
  end free_all;

  ------------------------------------------------------------------
  --------------------- Initialization Session ---------------------
  ------------------------------------------------------------------
begin
  $if $$plsql_optimize_level < 3 $then
    $error $$plsql_unit || ' must be compiled with PLSQL_OPTIMIZE_LEVEL=3' $end
  $end
  null;
exception when others then
  raise_application_error(-20904, $$plsql_unit || '<init>:' || $$plsql_line || nl || dbms_utility.format_error_stack);
end nksg_tempclob;
