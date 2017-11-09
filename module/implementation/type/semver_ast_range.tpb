create or replace type body semver_ast_range as

    ----------------------------------------------------------------------------
    constructor function semver_ast_range
    (
        text        in varchar2,
        range_type  in varchar2,
        comparators in semver_AstChildren
    ) return self as result is
    begin
        self.text        := text;
        self.range_type  := range_type;
        self.symbol_type := semver_range_parser.ast_Range;
        self.children    := comparators;
        --
        return;
    end;

    ----------------------------------------------------------------------------
    static function createNew
    (
        text        in varchar2,
        range_type  in varchar2,
        comparators in semver_AstChildren
    ) return semver_ast_range is
        l_Result semver_ast_range;
    begin
        l_Result := new semver_ast_range(text, range_type, comparators);
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
                return chr(10) || lpad(' ', 2 * lvl, ' ') || self.symbol_type || ':' || self.range_type;
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
