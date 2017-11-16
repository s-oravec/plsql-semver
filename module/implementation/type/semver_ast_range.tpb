create or replace type body semver_ast_range as

    ----------------------------------------------------------------------------
    constructor function semver_ast_range
    (
        range_type  in varchar2,
        comparators in semver_AstChildren
    ) return self as result is
    begin
        self.range_type  := range_type;
        self.symbol_type := semver_range_parser.ast_Range;
        self.children    := comparators;
        --
        return;
    end;

    ----------------------------------------------------------------------------
    static function createNew
    (
        range_type  in varchar2,
        comparators in semver_AstChildren
    ) return semver_ast_range is
        l_Result semver_ast_range;
    begin
        l_Result := new semver_ast_range(range_type, comparators);
        semver_ast_registry.register(l_Result);
        return l_Result;
    end;

    ----------------------------------------------------------------------------
    overriding member function toString return varchar2 is
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
        return '{ast:' || self.symbol_type || ',range_type:' || self.range_type || ',comparators:[' || l_children_tostring || ']}';
    end;

    ----------------------------------------------------------------------------
    member function get_range return semver_range is
        l_range_comparators     semver_comparators := new semver_comparators();
        l_primitive_comparators semver_comparators;
        l_ast_comparator        semver_ast_comparator;
    
        d debug := new debug('semver:translate:get_range');
        p semver_ast_partial;
    
        ----------------------------------------------------------------------------  
        function isX(identifier varchar2) return boolean is
        begin
            return identifier in('x', 'X', '*');
        end;
    
        ----------------------------------------------------------------------------  
        procedure appendComparator(comparator in semver_comparator) is
        begin
            l_range_comparators.extend();
            l_range_comparators(l_range_comparators.last) := comparator;
        end;
    
    begin
        d.log('range type: ' || self.range_type);
        if self.range_type = semver_range_parser.RANGE_TYPE_HYPHEN then
            d.log('create comparators from hyphen range partials');
            d.log('translating lower');
            p := treat(semver_ast_registry.get_by_id(self.children(1)) as semver_ast_partial);
            if isX(p.major) then
                d.log('major is *');
                appendComparator(semver_comparator('*', null));
            elsif isX(p.minor) then
                d.log('minor is *');
                appendComparator(semver_comparator('>=', semver_version(p.major, 0, 0)));
            elsif isX(p.patch) then
                d.log('patch is *');
                appendComparator(semver_comparator('>=', semver_version(p.major, p.minor, 0)));
            else
                d.log('else');
                appendComparator(semver_comparator('>=', semver_version(p.major, p.minor, p.patch, p.prerelease.tags, p.build.tags)));
            end if;
            d.log('translating upper');
            p := treat(semver_ast_registry.get_by_id(self.children(2)) as semver_ast_partial);
            if isX(p.major) then
                d.log('major is *');
                appendComparator(semver_comparator('*', null));
            elsif isX(p.minor) then
                d.log('minor is *');
                appendComparator(semver_comparator('<', semver_version(p.major + 1, 0, 0)));
            elsif isX(p.patch) then
                d.log('patch is *');
                appendComparator(semver_comparator('<', semver_version(p.major, p.minor + 1, 0)));
            elsif p.prerelease is not null then
                d.log('prerelease is not null');
                appendComparator(semver_comparator('<=', semver_version(p.major, p.minor, p.patch, p.prerelease.tags)));
            else
                d.log('else');
                appendComparator(semver_comparator('<=', semver_version(p.major, p.minor, p.patch, p.prerelease.tags, p.build.tags)));
            end if;
        
        else
            d.log('append simple comparator items');
            if self.children is not null and self.children.count > 0 then
                for l_idxChild in 1 .. self.children.count loop
                    d.log('get comparator from registry');
                    l_ast_comparator := treat(semver_ast_registry.get_by_id(self.children(l_idxChild)) as semver_ast_comparator);
                    d.log('get primitive comparators');
                    l_primitive_comparators := l_ast_comparator.get_primitve_comparators();
                    d.log('append them to range''s comparators');
                    for l_idxPrimitiveComparator in 1 .. l_primitive_comparators.count loop
                        appendComparator(l_primitive_comparators(l_idxPrimitiveComparator));
                    end loop;
                end loop;
            end if;
        end if;
        return new semver_range(comparators => l_range_comparators);
    exception
        when others then
            d.log('exception>' || sqlerrm);
    end;

end;
/
