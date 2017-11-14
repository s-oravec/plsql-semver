create or replace type semver_ast_RangeSet under semver_AST
(

    constructor function semver_ast_RangeSet(ranges semver_AstChildren) return self as result,

    static function createNew(ranges semver_AstChildren) return semver_ast_RangeSet,

    member function get_range_set return semver_range_set

)
/
