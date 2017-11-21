create or replace type semver_range as object
(
/**

SemVer Range object - set of SemVer Comparator sets

*/

/**

collection of SemVer Comparator sets

*/
    comparator_sets semver_comparator_sets,

/**

Creates instance of SemVer Range by parsing string passed as param
If parse fails then raises exception

%param range SemVer Range  string
%return semver_range object

*/
    constructor function semver_range(range in varchar2) return self as result,

/**

Returns formatted object as string

%return formatted object as string

*/
    member function to_string return varchar2,

/**
    
Version satisfies at least one set of Comparators in Rage

%param version SemVer Version object
%return result of comparison
    
*/
    member function test(version in semver_version) return boolean,

/**
    
SemVer Range intersects SemVer Range passed as paramter
    
%param range_ SemVer Range  object
    
*/
    member function intersects(range in semver_range) return boolean

)
;
/
