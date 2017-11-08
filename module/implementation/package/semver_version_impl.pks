create or replace package semver_version_impl as

    -- MAX_SAFE_INTEGER = Number.MAX_SAFE_INTEGER || 9007199254740991;
    MAX_SAFE_INTEGER constant pls_integer := power(2, 31) - 1;

    /**
    Validates version and returns it when it is valid SemVer version
    
    %param a_value SemVer version string
    %return valid SemVer version string
    
    */
    function valid(a_value in varchar2) return varchar2;

    /**
    Parses value and returns semver object
    
    %param a_value SemVer version string to be parsed
    %return semver_type
    
    */
    function parse(a_value in varchar2) return semver_version;

    procedure inc
    (
        a_this       in out nocopy semver_version,
        a_release    in varchar2,
        a_identifier in varchar2
    );

    /**
    Returns SemVer object as string
    
    %param a_semver SemVer object
    %return SemVer object formatted as string
    
    */
    function to_string(a_semver in semver_version) return varchar2;

    /**
    Trims value and returns valid SemVer string
    
    %param a_value SemVer string
    %return SmVer object formatted as string
    
    */
    function clean(a_value in varchar2) return varchar2;

    function compare
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return semver.compare_result_type;

    function compareMain
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return semver.compare_result_type;

    function comparePrerelease
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return semver.compare_result_type;

    function compareIdentifiers
    (
        a_this  in varchar2,
        a_other in varchar2
    ) return semver.compare_result_type;

    function rcompareIdentifiers
    (
        a_this  in varchar2,
        a_other in varchar2
    ) return semver.compare_result_type;

    function gt
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return boolean;

    function lt
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return boolean;

    function eq
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return boolean;

    function neq
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return boolean;

    function gte
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return boolean;

    function lte
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return boolean;

end;
/
