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

    ----------------------------------------------------------------------------
    member function get_range_set return semver_range_set is
        l_ranges semver_ranges;
    begin
        if self.children is not null and self.children.count > 0 then
            l_ranges := new semver_ranges();
            l_ranges.extend(self.children.count);
            for l_idx in 1 .. self.children.count loop
                l_ranges(l_idx) := treat(semver_ast_registry.get_by_id(self.children(l_idx)) as semver_ast_range).get_range();
            end loop;
            return new semver_range_set(l_ranges);
        else
            return null;
        end if;
    end;

end;
/
