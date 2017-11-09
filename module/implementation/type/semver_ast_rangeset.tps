create or replace type semver_ast_RangeSet under semver_AST (

    CONSTRUCTOR FUNCTION semver_ast_RangeSet(ranges semver_AstChildren) RETURN SELF AS Result,

    STATIC FUNCTION createNew(ranges semver_AstChildren) RETURN semver_ast_RangeSet
    
)
/
