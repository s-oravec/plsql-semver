create or replace type semver_range_set as object
(
/**

    SemVer Range Set objects - set of SemVer Ranges

    */

/**

    collection of semver_range objects in set

    */
    ranges semver_ranges,

/**

    Creates instance of SemVer Range Set by parsing string passed as param
    If parse failes then raises exception

    %param value SemVer Range set string
    %return semver_range_set object

    */
    constructor function semver_range_set(value in varchar2) return self as result,

/**

    Returns formatted object as string

    %return formatted object as string

    */
    member function to_string return varchar2,

/**
    
    Version satisfies at least one Range definition in Rage Set

    %param version SemVer Version object
    %return result of comparison
    
    */
    member function test(version in semver_version) return boolean,

/**
    
    SemVer Range Set intersects SemVer Range Set passed as paramter
    
    %param range_set SemVer Range Set object
    
    */
    member function intersects(range_set in semver_range_set) return boolean

)
;
/
