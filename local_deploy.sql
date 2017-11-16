conn sys/oracle@local as sysdba

@drop configured development

@create configured development
@package
@set_current_schema &&g_schema_name

rem install modules
cd oradb_modules

rem --------------------------------------------------------
rem install pete
cd pete
@install
cd ..

rem --------------------------------------------------------
rem install debug
cd debug
@install peer
cd ..

rem modules installed
cd ..

rem --------------------------------------------------------
rem install semver
@install peer development
