create or replace type semver_comparator_set as object
(
/**

Subset of SemVer Range Comparators

*/

/**

Comparators in SemVer Comparator Set

*/
    comparators semver_comparators,

/**

Return SemVer Comaparator Set object formatted as string

%return SemVer Comaparator Set object formatted as string

*/
    member function to_string return varchar2,

/**
    
Version satisfies all Comparators in Set
    
%param a_version SemVer Version object
%return result of comparison
    
*/
    member function test(version in semver_version) return boolean

)
;
/
