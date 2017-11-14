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
    member function toString return varchar2 is
        l_children_tostring varchar2(32767);
        l_child             semver_ast;
    begin
        if self.children.count > 0 then
            for idx in 1 .. self.children.count loop
                l_child             := semver_ast_registry.get_by_id(self.children(idx));
                l_children_tostring := l_children_tostring ||
                                       semver_util.ternary_varchar2(idx = 1, l_child.toString(), ',' || l_child.toString());
            end loop;
        end if;
        return '{ast:' || self.symbol_type || ',ranges:[' || l_children_tostring || ']}';
    end;

    ----------------------------------------------------------------------------
    member function executeAst return semver_ast is
    begin
        return null;
    end;

end;
/
