create or replace type semver_comparator as object
(
    text     varchar2(255),
    type     varchar2(30), -- primitive | tilde | caret
    modifier varchar2(2), -- ~ | ^ | < | > | <= | >= | =
    partial  semver_partial
)
;
/
