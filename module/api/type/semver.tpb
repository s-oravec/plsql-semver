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
        self.major := l_parsed_semver.major;
        self.minor := l_parsed_semver.minor;
        self.patch := l_parsed_semver.patch;
        --
        self.prerelease := l_parsed_semver.prerelease;
        self.build      := l_parsed_semver.build;
        --
        return;
        --
    end;

    ----------------------------------------------------------------------------
    member function to_string return varchar2 is
    begin
        return semver_impl.to_string(self);
    end;

    ----------------------------------------------------------------------------
    static function valid(value in varchar2) return varchar2 is
    begin
        return semver_impl.valid(value);
    end;

end;
/
