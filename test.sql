set serveroutput on size unlimited

prompt .. Resetting packages
begin
    dbms_session.reset_package;
end;
/

prompt .. Re-enabling DBMS_OUTPUT
begin
    dbms_output.enable;
end;
/

prompt .. Executing all test in current schema
exec pete.run_test_suite(a_suite_name_in => sys_context('userEnv', 'current_schema'));

prompt done
