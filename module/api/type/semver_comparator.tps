create or replace type semver_comparator as object
(
/**
    
SemVer Comparator
    
*/

/** Comparator Operator - = | >= | <= | > | < | */
    operator varchar2(2),

/** SemVer Version - if null then it means ANY Version */
    version semver_version,

/**

Return Comparator formatted as string.

%return Comparator formatted as string

*/
    member function to_string return varchar2,

/**

Version satisfies comparision with Comparator version and operator.

%param version SemVer Version object
%return result of comparison version self.operator self.version. e.g.: version < 1.2.0

*/
    member function test(version in semver_version) return boolean,

/**
        
Comparator intersects Comparator passed as parameter.
        
%param comparatator Comparator object
%return boolean result
        
*/
    member function intersects(comparator in semver_comparator) return boolean,

/**

Compare with Comparator object passed as param.

%param comparator Comparator object
%return comparison result -1 - less than, 0 - equal, 1 - greater than see semver.compare_result_type

*/
    order member function compare(comparator in semver_comparator) return pls_integer
)
;
/
