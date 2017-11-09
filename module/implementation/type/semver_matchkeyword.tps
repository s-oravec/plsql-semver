create or replace type semver_matchkeyword under semver_matcher
(
    tokenType        varchar2(30), -- semver_lexer.tokenType
    stringToMatch    varchar2(255), -- longest supported token
    allowAsSubstring varchar2(1), -- Y/N

    constructor function semver_matchkeyword
    (
        tokenType        in varchar2,
        stringToMatch    in varchar2,
        allowAsSubstring in varchar2 default 'Y'
    ) return self as result,

    overriding member function isMatchImpl return semver_token

)
;
/
