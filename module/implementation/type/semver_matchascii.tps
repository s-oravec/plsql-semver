create or replace type semver_matchASCII under semver_matcher
(

    constructor function semver_matchASCII return self as result,

    overriding member function isMatchImpl return semver_token

)
;
/
