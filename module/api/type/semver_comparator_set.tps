create or replace type semver_comparator_set as object
(
/**

    SemVer Range represented as collection of Comparators

    */

/**

    Comparators in SemVer Range definition

    */
    comparators semver_comparators,

/**

    Returns SemVer Range object formatted as string

    */
    member function to_string return varchar2,

/**
    
    Version satisfies all Comparators in Range 
    
    %param a_version SemVer Version object
    %return result of comparison
    
    */
    member function test(version in semver_version) return boolean

)
;
/
