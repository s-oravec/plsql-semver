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

    member function to_string return varchar2,

    member function format return varchar2,

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

    member function gt(value in semver_version) return boolean,

    member function lt(value in semver_version) return boolean,

    member function eq(value in semver_version) return boolean,

    member function neq(value in semver_version) return boolean,

    member function gte(value in semver_version) return boolean,

    member function lte(value in semver_version) return boolean

)
;
/
