create or replace type semver_version as object
(
    major      integer,
    minor      integer,
    patch      integer,
    prerelease semver_tags,
    build      semver_tags,

    constructor function semver_version
    (
        major      in integer,
        minor      in integer,
        patch      in integer,
        prerelease semver_tags default null,
        build      semver_tags default null
    ) return self as result,

    constructor function semver_version(value in varchar2) return self as result,

    member function format return varchar2,

    member function to_string return varchar2,

/**
    Compares SemVer version with value
    %return comparison result- see semver.compare_result_type
      - -1 - less than
      -  0 - equal
      -  1 - grater than
    */
    member function compare(value in semver_version) return pls_integer,

    member function compareMain(value in semver_version) return pls_integer,

    member function comparePrerelease(value in semver_version) return pls_integer,

/**
    preminor will bump the version up to the next minor release, and immediately
    down to pre-release. premajor and prepatch work the same way.
    
    %param release which part of version to bump
      - premajor
      - preminor
      - prepatch
      - prerelease
      - major
      - minor
      - patch
    %param identifier prerelease identifier
    */
    member procedure inc
    (
        release    in varchar2,
        identifier in varchar2 default null
    ),

    -- TODO: DEPRECATED !!!
    member function gt(value in semver_version) return boolean,

    -- TODO: DEPRECATED !!!
    member function lt(value in semver_version) return boolean,

    -- TODO: DEPRECATED !!!
    member function eq(value in semver_version) return boolean,

    -- TODO: DEPRECATED !!!
    member function neq(value in semver_version) return boolean,

    -- TODO: DEPRECATED !!!
    member function gte(value in semver_version) return boolean,

    -- TODO: DEPRECATED !!!
    member function lte(value in semver_version) return boolean

    --- TODO: implement order function - https://docs.oracle.com/cd/B28359_01/appdev.111/b28371/adobjbas.htm#ADOBJ002

)
;
/
