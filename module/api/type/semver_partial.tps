create or replace type semver_partial as object
(
    text       varchar2(255),
    major      varchar2(255),
    minor      varchar2(255),
    patch      varchar2(255),
    prerelease semver_tags,
    build      semver_tags
)
;
/
