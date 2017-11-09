create or replace type semver_range as object
(
    text        varchar2(255),
    rangeType   varchar2(30), -- hyphen | simpleList
    comparators semver_comparators
)
;
/
