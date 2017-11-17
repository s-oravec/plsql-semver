create or replace package body semver_range_impl as

    d debug := new debug('semver:range');

    ---------------------------------------------------------------------------- 
    function parse(a_value in varchar2) return semver_range_set is
        l_ast_rangeset semver_ast_rangeset;
        l_range_set    semver_range_set;
    begin
        d.log('parse: "' || a_value || '"');
        d.log('initialize parser');
        semver_range_parser.initialize(a_value);
        begin
            d.log('parsing');
            l_ast_rangeset := semver_range_parser.parse;
            d.log('translating sevmer_ast_rangeset to semver_range_set');
            l_range_set := l_ast_rangeset.get_range_set;
            d.log('returning translated semver_range_set');
            return l_range_set;
        exception
            when others then
                raise;
        end;
    end;

    ----------------------------------------------------------------------------
    function satisfies
    (
        a_version   in semver_version,
        a_range_set in semver_range_set
    ) return boolean is
    begin
        if a_range_set is null or a_range_set.ranges is null or a_range_set.ranges.count = 0 then
            return false;
        else
            for i in 1 .. a_range_set.ranges.count loop
                if satisfies(a_version, a_range_set.ranges(i)) then
                    return true;
                end if;
            end loop;
            return false;
        end if;
    end;

    ----------------------------------------------------------------------------
    function satisfies
    (
        a_version in semver_version,
        a_range   in semver_range
    ) return boolean is
    begin
        return test(a_range, a_version);
    end;

    ----------------------------------------------------------------------------
    function test
    (
        a_range_set in semver_range_set,
        a_version   in semver_version
    ) return boolean is
    begin
        if a_range_set is null or a_range_set.ranges is null or a_range_set.ranges.count = 0 then
            return false;
        else
            for i in 1 .. a_range_set.ranges.count loop
                if test(a_range_set.ranges(i), a_version) then
                    return true;
                end if;
            end loop;
            return false;
        end if;
    end;

    ----------------------------------------------------------------------------
    function test
    (
        a_range   in semver_range,
        a_version in semver_version
    ) return boolean is
        l_allowed semver_version;
    begin
        if a_version is null then
            return false;
        else
            for i in 1 .. a_range.comparators.count loop
                if not semver_Comparator_impl.test(a_range.comparators(i), a_version) then
                    return false;
                end if;
            end loop;
        
            if a_version.prerelease is not null and a_version.prerelease.count > 0 then
                d.log('version "' || a_version.to_string() || '" has prerelease - check range "' || a_range.to_string() || '" comparators');
                -- Find the set of versions that are allowed to have prereleases
                -- For example, ^1.2.3-pr.1 desugars to >=1.2.3-pr.1 <2.0.0
                -- That should allow `1.2.3-pr.2` to pass.
                -- However, `1.2.4-alpha.notready` should NOT be allowed,
                -- even though it's within the range set by the comparators.
                for j in 1 .. a_range.comparators.count loop
                
                    if a_range.comparators(j).operator is null then
                        continue;
                    end if;
                
                    l_allowed := a_range.comparators(j).version;
                    -- NoFormat Start                
                    if l_allowed.prerelease is not null and l_allowed.prerelease.count > 0 then
                        if (l_allowed.major = a_version.major and 
                            l_allowed.minor = a_version.minor and 
                            l_allowed.patch = a_version.patch)
                        then
                            d.log('Comparator "' || a_range.comparators(j).to_string() || '" has same prerelease as version , yay!');
                            return true;
                        end if;
                    end if;
                    -- NoFormat End
                end loop;
            
                d.log('Version has a -prerelease, but it''s not one of the ones we like');
                return false;
            end if;
        
            return true;
        end if;
    end;

    ----------------------------------------------------------------------------  
    function intersects
    (
        a_this  in semver_range,
        a_other in semver_range
    ) return boolean is
    begin
        -- every comparator in this range intersects with every comparator in the other range
        for i in 1 .. a_this.comparators.count loop
            for j in 1 .. a_other.comparators.count loop
                if not semver_comparator_impl.intersects(a_this.comparators(i), a_other.comparators(j)) then
                    return false;
                end if;
            end loop;
        end loop;
        return true;
    end;

    ----------------------------------------------------------------------------
    function intersects
    (
        a_this  in semver_range_set,
        a_other in semver_range_set
    ) return boolean is
    begin
        if a_this is null or a_other is null then
            return false;
        end if;
        -- for some range in this set and some range in the other
        for i in 1 .. a_this.ranges.count loop
            for j in 1 .. a_other.ranges.count loop
                -- every comparator in this range intersects with every comparator in the other range
                if not intersects(a_this.ranges(i), a_other.ranges(j)) then
                    return true;
                end if;
            end loop;
        end loop;
        return false;
    end;

    ----------------------------------------------------------------------------
    function satisfying
    (
        a_versions           in semver_versions,
        a_range_set          in semver_range_set,
        a_aggregate_function in aggregate_function_type
    ) return semver_version is
        l_selected       semver_version;
        l_compare_result semver.compare_result_type;
    begin
        if a_aggregate_function = semver_range_impl.FN_MAX then
            l_compare_result := semver.COMPARE_RESULT_LT;
        elsif a_aggregate_function = semver_range_impl.FN_MIN then
            l_compare_result := semver.COMPARE_RESULT_GT;
        end if;
        for i in 1 .. a_versions.count loop
            if test(a_range_set, a_versions(i)) then
                -- satisfies(version, range)
                if l_selected is null or l_selected.compare(a_versions(i)) = l_compare_result then
                    -- previous max/min is less than/greater than
                    l_selected := a_versions(i);
                end if;
            end if;
        end loop;
        return l_selected;
    end;

end;
/
