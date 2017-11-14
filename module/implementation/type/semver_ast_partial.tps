create or replace type semver_ast_partial under semver_AST
(
-- TODO: rename to something better

    major      varchar2(255),
    minor      varchar2(255),
    patch      varchar2(255),
    prerelease semver_ast_tags,
    build      semver_ast_tags,

    constructor function semver_ast_partial
    (
        major      in varchar2,
        minor      in varchar2,
        patch      in varchar2,
        prerelease in semver_ast_tags default null,
        build      in semver_ast_tags default null
    ) return self as result,

    static function createNew
    (
        major      in varchar2,
        minor      in varchar2,
        patch      in varchar2,
        prerelease in semver_ast_tags default null,
        build      in semver_ast_tags default null
    ) return semver_ast_partial,

    overriding member function toString return varchar2

)
;
/
