------------------------------------------------------------------------------------------------------------------------
-- @nksg-schema.sql: Optional "NKSG: PL/SQL Simple Generator" user/owner/schema creation
------------------------------------------------------------------------------------------------------------------------
-- The GRANTs required are: 'create session', 'create table', 'create procedure';
------------------------------------------------------------------------------------------------------------------------
declare
  lv__          constant varchar2(100) := 'Anonymous PL/SQL Block';
  lv_username   constant varchar2(30)  := 'nksg';
  lv_password   constant varchar2(30)  := 'nksg';
  lv_tablespace constant varchar2(30)  := 'users';
  lv_temp       constant varchar2(30)  := 'temp';
  nl            constant varchar2(3)   := '
';
  lv_stmt       varchar2(2048);
begin
  dbms_output.enable(buffer_size => 1e6);

  -- create user
  lv_stmt := ' create user '          || lv_username
          || ' identified by '        || lv_password
          || ' default tablespace '   || lv_tablespace
          || ' temporary tablespace ' || lv_temp
          || ' account unlock';
  dbms_output.put_line(lv_stmt);
  execute immediate lv_stmt;

  -- tablespace quota
  lv_stmt := ' alter user '          || lv_username
          || ' quota unlimited on '  || lv_tablespace;
  dbms_output.put_line(lv_stmt);
  execute immediate lv_stmt;

  -- grants
  lv_stmt := 'grant create session to '   || lv_username;
  dbms_output.put_line(lv_stmt);
  execute immediate lv_stmt;
  lv_stmt := 'grant create table to '     || lv_username;
  dbms_output.put_line(lv_stmt);
  execute immediate lv_stmt;
  lv_stmt := 'grant create procedure to ' || lv_username;
  dbms_output.put_line(lv_stmt);
  execute immediate lv_stmt;
exception when others then
  raise_application_error(-20777, lv__ || $$plsql_line || nl || dbms_utility.format_error_stack);
end;
/
