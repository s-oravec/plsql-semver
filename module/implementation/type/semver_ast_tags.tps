create or replace type semver_ast_tags under semver_AST
(

    tags semver_tags,

    constructor function semver_ast_tags(tags in semver_tags) return self as result,

    static function createNew(tags in semver_tags) return semver_ast_tags,

    overriding member function toString return varchar2

)
/
