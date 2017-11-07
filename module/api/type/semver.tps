create or replace type semver as object
(
-- Note: this is the semver.org version of the spec that it implements
-- Not necessarily the package version of this code.
-- SEMVER_SPEC_VERSION constant varchar2(10) := '2.0.0',

    major      integer,
    minor      integer,
    patch      integer,
    prerelease semver_tags,
    build      semver_tags,

    constructor function semver
    (
        major      in integer,
        minor      in integer,
        patch      in integer,
        prerelease semver_tags default null,
        build      semver_tags default null
    ) return self as result,

    constructor function semver(value in varchar2) return self as result,

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

    static function valid(value in varchar2) return varchar2,

    static function clean(value in varchar2) return varchar2,

    static function inc
    (
        value      in varchar2,
        release    in varchar2,
        identifier in varchar2 default null
    ) return varchar2
)
;
/
