create or replace type body semver_ast_comparator as

    ----------------------------------------------------------------------------
    constructor function semver_ast_comparator
    (
        text     in varchar2,
        type     in varchar2,
        modifier in varchar2,
        partial  in semver_ast_partial
    ) return self as result is
    begin
        self.symbol_type := semver_range_parser.ast_Comparator;
        --
        self.text     := text;
        self.type     := type;
        self.modifier := modifier;
        self.children := semver_ASTChildren();
        --
        if partial is not null then
            self.children.extend;
            self.children(self.children.last) := partial.id_registry;
        end if;
        --
        return;
    end;

    ----------------------------------------------------------------------------
    static function createNew
    (
        text     in varchar2,
        type     in varchar2,
        modifier in varchar2,
        partial  in semver_ast_partial
    ) return semver_ast_comparator is
        l_Result semver_ast_comparator;
    begin
        l_Result := new semver_ast_comparator(text, type, modifier, partial);
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
                RETURN chr(10) || lpad(' ', 2 * lvl, ' ')
                    || self.symbol_type || ':' ||  self.type || ':' || self.modifier;
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
