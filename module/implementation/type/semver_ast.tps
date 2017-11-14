create or replace type semver_ast as object
(
    id_registry integer,
    symbol_type varchar2(30), -- semver.as_symbol_type
    token       semver_token,
    children    semver_AstChildren,

    constructor function semver_ast(token semver_token) return self as result,

    static function createNew(token in semver_token) return semver_ast,

    constructor function semver_ast(symbol_type in varchar2) return self as result,

    static function createNew(symbol_type in varchar2) return semver_ast,

    member procedure addChild(child semver_ast),

    member function toString return varchar2,

    member function executeAst return semver_ast

)
not final;
/
