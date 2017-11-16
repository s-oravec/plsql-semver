create or replace type semver_comparator as object
(
    operator varchar2(2),
    version  semver_version,

    member function to_string return varchar2,

/**

    Version satisfies comparision with Comparator version and operator

    %param version SemVer Version object
    %return result of comparison version self.operator self.version. e.g.: version < 1.2.0

    */
    member function test(version in semver_version) return boolean,

/**
        
        Comparator intersects Comparator passed as parameter
        
        %param comparatator Comparator object
        %return boolean result
        
        */
    member function intersects(comparator in semver_comparator) return boolean
)
;
/
