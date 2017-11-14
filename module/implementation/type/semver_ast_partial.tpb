create or replace type body semver_ast_partial as

    ----------------------------------------------------------------------------
    constructor function semver_ast_partial
    (
        major      in varchar2,
        minor      in varchar2,
        patch      in varchar2,
        prerelease in semver_ast_tags default null,
        build      in semver_ast_tags default null
    ) return self as result is
    begin
        self.symbol_type := semver_range_parser.ast_partial;
        --
        self.major      := major;
        self.minor      := minor;
        self.patch      := patch;
        self.prerelease := prerelease;
        self.build      := build;
        --
        return;
    end;

    ----------------------------------------------------------------------------
    static function createNew
    (
        major      in varchar2,
        minor      in varchar2,
        patch      in varchar2,
        prerelease in semver_ast_tags default null,
        build      in semver_ast_tags default null
    ) return semver_ast_partial is
        l_Result semver_ast_partial;
    begin
        l_Result := new semver_ast_partial(major, minor, patch, prerelease, build);
        semver_ast_registry.register(l_Result);
        return l_Result;
    end;

    ----------------------------------------------------------------------------
    overriding member function toString return varchar2 is
    begin
        -- NoFormat Start
        return '{' 
            || 'ast:' || self.symbol_type || ','
            || 'version:"' || self.major || '"'
            || case when self.minor is not null then '."' || self.minor || '"' else null end 
            || case when self.patch is not null then '."' || self.patch || '"' else null end 
            || case when self.prerelease is not null then '-' || self.prerelease.toString() end 
            || case when self.build is not null then '+' || self.build.toString() end 
            || '}'
            ;
        -- NoFormat End
    end;

end;
/
