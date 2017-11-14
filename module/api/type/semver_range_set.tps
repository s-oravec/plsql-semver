create or replace type semver_range_set as object
(
    ranges semver_ranges,

    member function to_string return varchar2
)
;
/
