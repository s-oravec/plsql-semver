create or replace package semver_comparator_impl as

    /**
    
    SemVer Comparator implementation package
    
    */

    /**
    
    Test comparison of a_this.version and a_version using a_this.operator
    
    %param a_this comparator
    %param a_version version to compare
    %return result of test
    
    */
    function test
    (
        a_this    in semver_comparator,
        a_version in semver_version
    ) return boolean;

    /**
    
    Comparators intersect
    
    %param a_this a comparator
    %param a_other another comparator
    %return result of intersect statement
    
    */
    function intersects
    (
        a_this  in semver_comparator,
        a_other in semver_comparator
    ) return boolean;

end;
/
