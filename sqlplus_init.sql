prompt
prompt SQL*Plus Run Configuration
prompt .. Ensuring that SQL*Plus ErrorLog table exists

set errorlogging off
set feedback off

begin
    execute immediate
    -- NoFormat Start
    'create table &&_user..sqlplus_log (' || chr(10) ||
    '    username   varchar(256),' || chr(10) ||
    '    timestamp  timestamp,' || chr(10) ||
    '    script     varchar(1024),' || chr(10) ||
    '    identifier varchar(256),' || chr(10) ||
    '    message    clob,' || chr(10) ||
    '    statement  clob' || chr(10) ||
    ')';
    -- NoFormat End
exception
    when others then null;
end;
/

begin
    execute immediate 'grant select on &&_user..sqlplus_log to public';
exception
    when others then null;
end;
/

column g_run_identifier new_value g_run_identifier
set termout off
select rawtohex(sys_guid()) as g_run_identifier from dual;
set termout on

prompt .. Setting SQL*Plus ErrorLog table with identifier = &&g_run_identifier
set errorlogging on table &&_user..sqlplus_log identifier &&g_run_identifier

prompt done
prompt
