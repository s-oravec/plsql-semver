create or replace type semver_ast_partial under semver_AST
(
    -- TODO: rename to something better
    
    text  varchar2(255),
    major varchar2(255),
    minor varchar2(255),
    patch varchar2(255),

    constructor function semver_ast_partial
    (
        text       in varchar2,
        major      in varchar2,
        minor      in varchar2,
        patch      in varchar2,
        prerelease in semver_ast_tags default null,
        build      in semver_ast_tags default null
    ) return self as result,

    static function createNew
    (
        text       in varchar2,
        major      in varchar2,
        minor      in varchar2,
        patch      in varchar2,
        prerelease in semver_ast_tags default null,
        build      in semver_ast_tags default null
    ) return semver_ast_partial,

    overriding member function toString
    (
        lvl       integer default 0,
        verbosity integer default 0
    ) return varchar2

)
;
/
