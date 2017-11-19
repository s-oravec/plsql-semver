create or replace type semver_ast_Range under semver_AST
(

    constructor function semver_ast_Range(ranges semver_AstChildren) return self as result,

    static function createNew(ranges semver_AstChildren) return semver_ast_Range,

    member function get_range return semver_range

)
/
