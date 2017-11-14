create or replace type semver_ast_comparator under semver_AST
(

    type varchar2(30), -- primitive | tilde | caret
-- TODO: rename to oper
    oper    varchar2(2), -- ~ | ^ | < | > | <= | >= | =
    partial semver_ast_partial,

    constructor function semver_ast_comparator
    (
        type    in varchar2,
        oper    in varchar2,
        partial in semver_ast_partial
    ) return self as result,

    static function createNew
    (
        type    in varchar2,
        oper    in varchar2,
        partial in semver_ast_partial
    ) return semver_ast_comparator,

    overriding member function toString return varchar2,

/**

    tilde and caret comparator are translated to pair of primitive comparators

    */
    member function get_primitve_comparators return semver_comparators

)
;
/
