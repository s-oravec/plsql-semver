create or replace type semver_matcher as object
(

    dummy integer,

    member function isMatch return semver_token,

    member function isMatchImpl return semver_token

)
not final;
/
