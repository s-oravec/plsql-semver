create or replace type semver_matchNumeric under semver_matcher
(

    constructor function semver_matchNumeric return self as result,

    overriding member function isMatchImpl return semver_token

)
;
/
