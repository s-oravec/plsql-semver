create or replace type semver_token as object
(
    tokenType   varchar2(30), -- see semver_lexer.TokenType
    text        varchar2(4000),
    sourceIndex integer, -- position in source

-- TODO: move methods to some descendant type, do not expose them in API
    constructor function semver_token(tokenType in varchar2) return self as result,

    constructor function semver_token
    (
        tokenType in varchar2,
        text      in varchar2
    ) return self as result,

    member function matchText
    (
        text       in varchar,
        ignoreCase boolean default true
    ) return boolean
)
/
