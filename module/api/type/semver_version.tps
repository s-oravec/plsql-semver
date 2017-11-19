create or replace type semver_version as object
(
/**

SemVer Version object

*/

/**

SemVer Version major part

*/
    major integer,

/**

SemVer Version minor part

*/
    minor integer,

/**

SemVer Version patch part

*/
    patch integer,

/**

SemVer Version prerelease tags

*/
    prerelease semver_tags,

/**

SemVer Version build tags

*/
    build semver_tags,

/**

Constructor function create SemVer Version object if passed versions make up valid SemVer range object. Otherwise exception is thrown.

%param major major version
%param minor minor version
%param patch patch version
%param prerelease prerelease SemVer tags
%param build build SemVer tags
%return SemVer Version object

*/
    constructor function semver_version
    (
        major      in integer,
        minor      in integer,
        patch      in integer,
        prerelease semver_tags default null,
        build      semver_tags default null
    ) return self as result,

/**

Constructor function create SemVer Version object from SemVer Version string. If string is invalid it throws exception.

%param version SemVer Version string to be parsed
%return SemVer Version object

*/
    constructor function semver_version(version in varchar2) return self as result,

/**

Return formatted SemVer object as string

*/
    member function to_string return varchar2,

/**

Compares SemVer version with version
%return comparison result- see semver.compare_result_type
  - -1 - less than
  -  0 - equal
  -  1 - grater than

*/
    order member function compare(version in semver_version) return pls_integer,

    member function compareMain(version in semver_version) return pls_integer,

    member function comparePrerelease(version in semver_version) return pls_integer,

/**

Use vhen creating new release

preminor will bump the version up to the next minor release, and immediately
down to pre-release. premajor and prepatch work the same way.
    
%param release which type of release you are creating
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
    )

)
;
/
