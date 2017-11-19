create or replace type body semver_ast_Range as

    ----------------------------------------------------------------------------
    constructor function semver_ast_Range(ranges in semver_AstChildren) return self as result is
    begin
        self.symbol_type := semver_range_parser.ast_RangeSet;
        self.children    := ranges;
        return;
    end;

    ----------------------------------------------------------------------------
    static function createNew(ranges in semver_AstChildren) return semver_ast_Range is
        l_Result semver_ast_Range;
    begin
        l_Result := new semver_ast_Range(ranges);
        semver_ast_registry.register(l_Result);
        return l_Result;
    end;

    ----------------------------------------------------------------------------
    member function get_range return semver_range is
        l_comparator_sets semver_comparator_sets;
    begin
        if self.children is not null and self.children.count > 0 then
            l_comparator_sets := new semver_comparator_sets();
            l_comparator_sets.extend(self.children.count);
            for l_idx in 1 .. self.children.count loop
                l_comparator_sets(l_idx) := treat(semver_ast_registry.get_by_id(self.children(l_idx)) as semver_ast_comparatorset)
                                            .get_comparator_set();
            end loop;
            return new semver_range(l_comparator_sets);
        else
            return null;
        end if;
    end;

end;
/
