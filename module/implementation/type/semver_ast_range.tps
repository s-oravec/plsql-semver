create or replace type semver_ast_range under semver_AST
(
    range_type varchar2(30), -- hyphen, simple

    constructor function semver_ast_range
    (
        range_type  in varchar2,
        comparators in semver_AstChildren
    ) return self as result,

    static function createNew
    (
        range_type  in varchar2,
        comparators in semver_AstChildren
    ) return semver_ast_range,

    overriding member function toString return varchar2,

    member function get_range return semver_range

)
;
/
