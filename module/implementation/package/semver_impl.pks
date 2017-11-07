create or replace package semver_impl as

    /**
    Validates version and returns it when it is valid SemVer version
    
    %param a_value SemVer version string
    %return valid SemVer version string
    
    */
    function valid(a_value in varchar2) return varchar2;

    /**
    Parses version and returns semver_type
    
    %param a_value SemVer version string to be parsed
    %return semver_type
    
    */
    function parse(a_value in varchar2) return semver;
    
    /**
    Return SemVer object as string
    
    %param a_semver SemVer object
    %return SemVer object formatted as string
    
    */
    function to_string(a_semver in semver) return varchar2;

end;
/
