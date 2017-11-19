create or replace type semver_ast_ComparatorSet under semver_AST
(
    range_type varchar2(30), -- hyphen, simple

    constructor function semver_ast_ComparatorSet
    (
        range_type  in varchar2,
        comparators in semver_AstChildren
    ) return self as result,

    static function createNew
    (
        range_type  in varchar2,
        comparators in semver_AstChildren
    ) return semver_ast_ComparatorSet,

    overriding member function toString return varchar2,

    member function get_comparator_set return semver_comparator_set

)
;
/
