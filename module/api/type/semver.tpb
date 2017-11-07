create or replace type body semver as

    ----------------------------------------------------------------------------  
    constructor function semver
    (
        major      in integer,
        minor      in integer,
        patch      in integer,
        prerelease semver_tags default null,
        build      semver_tags default null
    ) return self as result is
    begin
        -- validate
        if major > semver_impl.MAX_SAFE_INTEGER or major < 0 then
            raise_application_error(-20000, 'Invalid major version');
        end if;
        if minor > semver_impl.MAX_SAFE_INTEGER or minor < 0 then
            raise_application_error(-20000, 'Invalid minor version');
        end if;
        if patch > semver_impl.MAX_SAFE_INTEGER or patch < 0 then
            raise_application_error(-20000, 'Invalid patch version');
        end if;
        --
        self.major      := major;
        self.minor      := minor;
        self.patch      := patch;
        self.prerelease := prerelease;
        self.build      := build;
        --
        return;
        --
    end;

    ----------------------------------------------------------------------------  
    constructor function semver(value in varchar2) return self as result is
        l_parsed_semver semver;
    begin
        -- parse semver string
        l_parsed_semver := semver_impl.parse(value);
        -- fill attributes
        self.major      := l_parsed_semver.major;
        self.minor      := l_parsed_semver.minor;
        self.patch      := l_parsed_semver.patch;
        self.prerelease := l_parsed_semver.prerelease;
        self.build      := l_parsed_semver.build;
        --
        return;
        --
    end;

    ----------------------------------------------------------------------------  
    member procedure inc
    (
        release    in varchar2,
        identifier in varchar2 default null
    ) is
    begin
        semver_impl.inc(self, release, identifier);
    end;

    ----------------------------------------------------------------------------
    static function inc
    (
        value      in varchar2,
        release    in varchar2,
        identifier in varchar2 default null
    ) return varchar2 is
    begin
        return semver_impl.inc(value, release, identifier);
    end;

    ----------------------------------------------------------------------------
    member function to_string return varchar2 is
    begin
        return semver_impl.to_string(self);
    end;

    ----------------------------------------------------------------------------
    member function format return varchar2 is
    begin
        return semver_impl.to_string(self);
    end;

    ----------------------------------------------------------------------------
    static function valid(value in varchar2) return varchar2 is
    begin
        return semver_impl.valid(value);
    end;

    ----------------------------------------------------------------------------
    static function clean(value in varchar2) return varchar2 is
    begin
        return semver_impl.clean(value);
    end;

end;
/
