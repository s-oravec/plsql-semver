create or replace type body semver_ast_partial as

    ----------------------------------------------------------------------------
    constructor function semver_ast_partial
    (
        text       in varchar2,
        major      in varchar2,
        minor      in varchar2,
        patch      in varchar2,
        prerelease in semver_ast_tags default null,
        build      in semver_ast_tags default null
    ) return self as result is
    begin
        self.symbol_type := semver_range_parser.ast_partial;
        --
        self.text     := text;
        self.major    := major;
        self.minor    := minor;
        self.patch    := patch;
        self.children := new semver_ASTChildren();
        --
        if prerelease is not null then
            self.children.extend();
            self.children(self.children.last) := prerelease.id_registry;
        end if;
        if build is not null then
            self.children.extend();
            self.children(self.children.last) := build.id_registry;
        end if;
        --
        return;
    end;

    ----------------------------------------------------------------------------
    static function createNew
    (
        text       in varchar2,
        major      in varchar2,
        minor      in varchar2,
        patch      in varchar2,
        prerelease in semver_ast_tags default null,
        build      in semver_ast_tags default null
    ) return semver_ast_partial is
        l_Result semver_ast_partial;
    begin
        l_Result := new semver_ast_partial(text, major, minor, patch, prerelease, build);
        semver_ast_registry.register(l_Result);
        return l_Result;
    end;

    ----------------------------------------------------------------------------
    overriding member function toString
    (
        lvl       integer default 0,
        verbosity integer default 0
    ) return varchar2 is
        l_Result varchar2(32767);
        l_child  semver_ast;
    
        function strMe return varchar2 is
        begin
            if verbosity = 0 then
                return self.symbol_type;
            else
                -- NoFormat Start
                return chr(10) || lpad(' ', 2 * lvl, ' ') || self.symbol_type || ':'
                       || self.major 
                       || case when self.minor is not null then '.' || self.minor else null end 
                       || case when self.patch is not null then '.' || self.patch else null end
                ;
                -- NoFormat End
            end if;
        end;
    
        function strAfterChildren return varchar2 is
        begin
            if verbosity = 0 then
                return null;
            else
                return chr(10) || lpad(' ', 2 * lvl, ' ');
            end if;
        end;
    
    begin
        if self.children.count > 0 then
            for idx in 1 .. self.children.count loop
                l_child := semver_ast_registry.get_by_id(self.children(idx));
                if idx = 1 then
                    l_Result := l_Result || l_child.toString(lvl + 1, verbosity);
                else
                    l_Result := l_Result || ',' || l_child.toString(lvl + 1, verbosity);
                end if;
            end loop;
            return strMe || '(' || l_Result || strAfterChildren || ')';
        end if;
        return strMe;
    end;

end;
/
