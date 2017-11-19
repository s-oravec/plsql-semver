set serveroutput on size unlimited

clear screen

prompt .. Resetting packages
exec dbms_session.reset_package;

prompt .. Re-enabling DBMS_OUTPUT
exec dbms_output.enable;

prompt .. Executing all test in current schema
exec pete.run_test_suite(a_suite_name_in => sys_context('userEnv', 'current_schema'));

prompt done
