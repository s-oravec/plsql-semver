create or replace type body semver_version as

    ----------------------------------------------------------------------------  
    constructor function semver_version
    (
        major      in integer,
        minor      in integer,
        patch      in integer,
        prerelease semver_tags default null,
        build      semver_tags default null
    ) return self as result is
    begin
        -- validate
        if major > semver.MAX_SAFE_INTEGER or major < 0 then
            raise_application_error(-20000, 'Invalid major version');
        end if;
        if minor > semver.MAX_SAFE_INTEGER or minor < 0 then
            raise_application_error(-20000, 'Invalid minor version');
        end if;
        if patch > semver.MAX_SAFE_INTEGER or patch < 0 then
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
    constructor function semver_version(value in varchar2) return self as result is
        l_version semver_version;
    begin
        -- parse semver string
        l_version := semver_version_impl.parse(value);
        -- fill attributes
        self.major      := l_version.major;
        self.minor      := l_version.minor;
        self.patch      := l_version.patch;
        self.prerelease := l_version.prerelease;
        self.build      := l_version.build;
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
        semver_version_impl.inc(self, release, identifier);
    end;

    ----------------------------------------------------------------------------
    member function to_string return varchar2 is
    begin
        return semver_version_impl.to_string(self);
    end;

    ----------------------------------------------------------------------------
    member function format return varchar2 is
    begin
        return semver_version_impl.to_string(self);
    end;

    ----------------------------------------------------------------------------
    member function compare(value in semver_version) return pls_integer is
    begin
        return semver_version_impl.compare(self, value);
    end;

    ----------------------------------------------------------------------------
    member function compareMain(value in semver_version) return pls_integer is
    begin
        return semver_version_impl.compareMain(self, value);
    end;

    ----------------------------------------------------------------------------
    member function comparePrerelease(value in semver_version) return pls_integer is
    begin
        return semver_version_impl.compareMain(self, value);
    end;

    ----------------------------------------------------------------------------
    member function gt(value in semver_version) return boolean is
    begin
        return semver_version_impl.gt(self, value);
    end;

    ----------------------------------------------------------------------------
    member function lt(value in semver_version) return boolean is
    begin
        return semver_version_impl.lt(self, value);
    end;

    ----------------------------------------------------------------------------
    member function eq(value in semver_version) return boolean is
    begin
        return semver_version_impl.eq(self, value);
    end;

    ----------------------------------------------------------------------------
    member function neq(value in semver_version) return boolean is
    begin
        return semver_version_impl.neq(self, value);
    end;

    ----------------------------------------------------------------------------
    member function gte(value in semver_version) return boolean is
    begin
        return semver_version_impl.gte(self, value);
    end;

    ----------------------------------------------------------------------------
    member function lte(value in semver_version) return boolean is
    begin
        return semver_version_impl.lte(self, value);
    end;

end;
/
