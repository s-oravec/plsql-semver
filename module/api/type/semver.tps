create or replace type semver as object
(

    major      integer,
    minor      integer,
    patch      integer,
    prerelease semver_tags,
    build      semver_tags,

    constructor function semver
    (
        major      in integer,
        minor      in integer,
        patch      in integer,
        prerelease semver_tags default null,
        build      semver_tags default null
    ) return self as result,

    constructor function semver(value in varchar2) return self as result,
    
    member function to_string return varchar2,
    
    member function format return varchar2,

    static function valid(value in varchar2) return varchar2

)
;
/
