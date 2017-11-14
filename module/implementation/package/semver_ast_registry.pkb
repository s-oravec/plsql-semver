create or replace package body semver_ast_registry as

    d debug := new debug('semver:ast_registry');

    type typ_ast_table is table of semver_ast;
    g_ast_registry typ_ast_table;

    ----------------------------------------------------------------------------
    procedure initialize is
    begin
        g_ast_registry := typ_ast_table();
        d.log('initialized');
    end;

    ----------------------------------------------------------------------------  
    procedure register(ast in out nocopy semver_ast) is
    begin
        g_ast_registry.extend();
        g_ast_registry(g_ast_registry.last) := ast;
        ast.id_registry := g_ast_registry.last;
        d.log('registered [' || ast.id_registry || ']: ' || ast.toString());
    end;

    ----------------------------------------------------------------------------
    procedure unregister(ast in out nocopy semver_ast) is
    begin
        d.log('unregistering [' || ast.id_registry || ']: ' || ast.toString());
        g_ast_registry.delete(ast.id_registry);
        ast.id_registry := null;
    end;

    ----------------------------------------------------------------------------
    function get_by_id(id_registry in integer) return semver_ast is
    begin
        d.log('getting id: ' || id_registry);
        return g_ast_registry(id_registry);
    end;

end;
/
