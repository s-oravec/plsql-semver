create or replace type semver_ast_range under semver_AST
(
    text       varchar2(255),
    range_type varchar2(30), -- hyphen, simple

    constructor function semver_ast_range
    (
        text        in varchar2,
        range_type  in varchar2,
        comparators in semver_AstChildren
    ) return self as result,

    static function createNew
    (
        text        in varchar2,
        range_type  in varchar2,
        comparators in semver_AstChildren
    ) return semver_ast_range,

    overriding member function toString
    (
        lvl       integer default 0,
        verbosity integer default 0
    ) return varchar2

)
;
/
