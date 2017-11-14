create or replace type semver_range as object
(
    comparators semver_comparators,
    
    member function to_string return varchar2
)
;
/
