create or replace package semver_ast_registry as

    procedure initialize;

    procedure register(ast in out nocopy semver_ast);

    procedure unregister(ast in out nocopy semver_ast);

    function get_by_id(id_registry in integer) return semver_ast;

end;
/
