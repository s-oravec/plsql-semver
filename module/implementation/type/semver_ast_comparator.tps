create or replace type semver_ast_comparator under semver_AST
(

    text     varchar2(255),
    type     varchar2(30), -- primitive | tilde | caret
    -- TODO: rename to oper
    modifier varchar2(2), -- ~ | ^ | < | > | <= | >= | =

    constructor function semver_ast_comparator
    (
        text     in varchar2,
        type     in varchar2,
        modifier in varchar2,
        partial  in semver_ast_partial
    ) return self as result,

    static function createNew
    (
        text     in varchar2,
        type     in varchar2,
        modifier in varchar2,
        partial  in semver_ast_partial
    ) return semver_ast_comparator,

    overriding member function toString
    (
        lvl       integer default 0,
        verbosity integer default 0
    ) return varchar2

)
;
/
