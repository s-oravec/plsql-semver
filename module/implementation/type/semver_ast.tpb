create or replace type body semver_ast as

    ----------------------------------------------------------------------------
    constructor function semver_ast(token semver_token) return self as result is
    begin
        self.token       := token;
        self.symbol_type := token.tokenType;
        self.children    := semver_AstChildren();
        --
        return;
    end;

    ----------------------------------------------------------------------------
    static function createNew(token semver_token) return semver_ast is
        l_result semver_ast;
    begin
        l_result := semver_ast(token);
        semver_ast_registry.register(l_result);
        return l_result;
    end;

    ----------------------------------------------------------------------------
    constructor function semver_ast(symbol_type in varchar2) return self as result is
    begin
        self.token       := null;
        self.symbol_type := symbol_type;
        self.children    := semver_AstChildren();
        --
        return;
    end;

    ----------------------------------------------------------------------------    
    static function createNew(symbol_type in varchar2) return semver_ast is
        l_result semver_ast;
    begin
        l_result := semver_ast(symbol_type);
        semver_ast_registry.register(l_result);
        return l_result;
    end;

    ----------------------------------------------------------------------------
    member procedure addChild(child semver_ast) is
    begin
        if child is not null then
            children.extend;
            children(children.count) := child.id_registry;
        end if;
    end;

    ----------------------------------------------------------------------------
    member function toString
    (
        lvl       integer default 0,
        verbosity integer default 0
    ) return varchar2 is
        l_result varchar2(32767);
        l_child  semver_ast;
    
        function strMe return varchar2 is
        begin
            if verbosity = 0 then
                return self.symbol_type;
            else
                return chr(10) || lpad(' ', 2 * lvl, ' ') || self.symbol_type;
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
                    l_result := l_result || l_child.toString(lvl + 1, verbosity);
                else
                    l_result := l_result || ',' || l_child.toString(lvl + 1, verbosity);
                end if;
            end loop;
            return strMe || '(' || l_result || strAfterChildren || ')';
        end if;
        return strMe;
    end;

    ----------------------------------------------------------------------------
    member function executeAst return semver_ast is
    begin
        return null;
    end;

end;
/
