create or replace package semver_impl as

    -- MAX_SAFE_INTEGER = Number.MAX_SAFE_INTEGER || 9007199254740991;
    MAX_SAFE_INTEGER constant pls_integer := power(2, 31) - 1;

    subtype compare_result_type is pls_integer range - 1 .. 1;
    COMPARE_RESULT_LT constant compare_result_type := -1;
    COMPARE_RESULT_EQ constant compare_result_type := 0;
    COMPARE_RESULT_GT constant compare_result_type := 1;

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
    function parse(a_value in varchar2) return semver;

    procedure inc
    (
        a_this       in out nocopy semver,
        a_release    in varchar2,
        a_identifier in varchar2
    );

    function inc
    (
        a_value      in varchar2,
        a_release    in varchar2,
        a_identifier in varchar2
    ) return varchar2;

    /**
    Returns SemVer object as string
    
    %param a_semver SemVer object
    %return SemVer object formatted as string
    
    */
    function to_string(a_semver in semver) return varchar2;

    /**
    Trims value and returns valid SemVer string
    
    %param a_value SemVer string
    %return SmVer object formatted as string
    
    */
    function clean(a_value in varchar2) return varchar2;

end;
/
