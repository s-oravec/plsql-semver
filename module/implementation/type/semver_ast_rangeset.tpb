create or replace type body semver_ast_RangeSet as

    ----------------------------------------------------------------------------
    constructor function semver_ast_RangeSet(ranges in semver_AstChildren) return self as result is
    begin
        self.symbol_type := semver_range_parser.ast_RangeSet;
        self.children    := ranges;
        return;
    end;

    ----------------------------------------------------------------------------
    static function createNew(ranges in semver_AstChildren) return semver_ast_RangeSet is
        l_Result semver_ast_RangeSet;
    begin
        l_Result := new semver_ast_RangeSet(ranges);
        semver_ast_registry.register(l_Result);
        return l_Result;
    end;

end;
/
