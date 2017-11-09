create or replace package body semver_ast_registry as

    type typ_ast_table is table of semver_ast;
    g_ast_registry typ_ast_table;

    ----------------------------------------------------------------------------
    procedure initialize is
    begin
        g_ast_registry := typ_ast_table();
    end;

    ----------------------------------------------------------------------------  
    procedure register(ast in out nocopy semver_ast) is
    begin
        g_ast_registry.extend();
        g_ast_registry(g_ast_registry.last) := ast;
        ast.id_registry := g_ast_registry.last;
    end;

    ----------------------------------------------------------------------------
    procedure unregister(ast in out nocopy semver_ast) is
    begin
        g_ast_registry.delete(ast.id_registry);
        ast.id_registry := null;
    end;

    ----------------------------------------------------------------------------
    function get_by_id(id_registry in integer) return semver_ast is
    begin
        return g_ast_registry(id_registry);
    end;

end;
/
