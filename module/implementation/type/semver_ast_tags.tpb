create or replace type body semver_ast_tags as

    ----------------------------------------------------------------------------
    constructor function semver_ast_tags(tags in semver_tags) return self as result is
    begin
        self.symbol_type := semver_range_parser.ast_Tags;
        self.tags        := tags;
        return;
    end;

    ----------------------------------------------------------------------------
    static function createNew(tags in semver_tags) return semver_ast_tags is
        l_result semver_ast_tags;
    begin
        l_result := new semver_ast_tags(tags);
        semver_ast_registry.register(l_result);
        return l_result;
    end;

    ----------------------------------------------------------------------------
    overriding member function toString return varchar2 is
        l_result varchar2(255);
    begin
        for i in 1 .. self.tags.count loop
            l_result := l_result || semver_util.ternary_varchar2(i = 1, self.tags(i), '.' || self.tags(i));
        end loop;
        return l_result;
    end;

end;
/
