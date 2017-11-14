create or replace type semver_comparator as object
(
    operator varchar2(2),
    version  semver_version,

    member function to_string return varchar2

)
;
/
