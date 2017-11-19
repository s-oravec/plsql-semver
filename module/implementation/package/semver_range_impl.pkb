create or replace package body semver_range_impl as

    d debug := new debug('semver:range');

    ---------------------------------------------------------------------------- 
    function parse(a_value in varchar2) return semver_range is
        l_ast_range semver_ast_range;
        l_range     semver_range;
    begin
        d.log('parse: "' || a_value || '"');
        d.log('initialize parser');
        semver_range_parser.initialize(a_value);
        begin
            d.log('parsing');
            l_ast_range := semver_range_parser.parse;
            d.log('translating sevmer_ast_comparator_setset to semver_range');
            l_range := l_ast_range.get_range;
            d.log('returning translated semver_range');
            return l_range;
        exception
            when others then
                raise;
        end;
    end;

    ----------------------------------------------------------------------------
    function satisfies
    (
        a_version in semver_version,
        a_range   in semver_range
    ) return boolean is
    begin
        if a_range is null or a_range.comparator_sets is null or a_range.comparator_sets.count = 0 then
            return false;
        else
            for i in 1 .. a_range.comparator_sets.count loop
                if satisfies(a_version, a_range.comparator_sets(i)) then
                    return true;
                end if;
            end loop;
            return false;
        end if;
    end;

    ----------------------------------------------------------------------------
    function satisfies
    (
        a_version        in semver_version,
        a_comparator_set in semver_comparator_set
    ) return boolean is
    begin
        return test(a_comparator_set, a_version);
    end;

    ----------------------------------------------------------------------------
    function test
    (
        a_range   in semver_range,
        a_version in semver_version
    ) return boolean is
    begin
        if a_range is null or a_range.comparator_sets is null or a_range.comparator_sets.count = 0 then
            return false;
        else
            for i in 1 .. a_range.comparator_sets.count loop
                if test(a_range.comparator_sets(i), a_version) then
                    return true;
                end if;
            end loop;
            return false;
        end if;
    end;

    ----------------------------------------------------------------------------
    function test
    (
        a_comparator_set in semver_comparator_set,
        a_version        in semver_version
    ) return boolean is
        l_allowed semver_version;
    begin
        if a_version is null then
            return false;
        else
            for i in 1 .. a_comparator_set.comparators.count loop
                if not semver_Comparator_impl.test(a_comparator_set.comparators(i), a_version) then
                    return false;
                end if;
            end loop;
        
            if a_version.prerelease is not null and a_version.prerelease.count > 0 then
                d.log('version "' || a_version.to_string() || '" has prerelease - check range "' || a_comparator_set.to_string() ||
                      '" comparators');
                -- Find the set of versions that are allowed to have prereleases
                -- For example, ^1.2.3-pr.1 desugars to >=1.2.3-pr.1 <2.0.0
                -- That should allow `1.2.3-pr.2` to pass.
                -- However, `1.2.4-alpha.notready` should NOT be allowed,
                -- even though it's within the range set by the comparators.
                for j in 1 .. a_comparator_set.comparators.count loop
                
                    if a_comparator_set.comparators(j).operator is null then
                        continue;
                    end if;
                
                    l_allowed := a_comparator_set.comparators(j).version;
                    -- NoFormat Start                
                    if l_allowed.prerelease is not null and l_allowed.prerelease.count > 0 then
                        if (l_allowed.major = a_version.major and 
                            l_allowed.minor = a_version.minor and 
                            l_allowed.patch = a_version.patch)
                        then
                            d.log('Comparator "' || a_comparator_set.comparators(j).to_string() || '" has same prerelease as version , yay!');
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
        a_this  in semver_comparator_set,
        a_other in semver_comparator_set
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
        a_this  in semver_range,
        a_other in semver_range
    ) return boolean is
    begin
        if a_this is null or a_other is null then
            return false;
        end if;
        -- for some range in this set and some range in the other
        for i in 1 .. a_this.comparator_sets.count loop
            for j in 1 .. a_other.comparator_sets.count loop
                -- every comparator in this range intersects with every comparator in the other range
                if not intersects(a_this.comparator_sets(i), a_other.comparator_sets(j)) then
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
        a_range              in semver_range,
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
            if test(a_range, a_versions(i)) then
                -- satisfies(version, range)
                if l_selected is null or l_selected.compare(a_versions(i)) = l_compare_result then
                    -- previous max/min is less than/greater than
                    l_selected := a_versions(i);
                end if;
            end if;
        end loop;
        return l_selected;
    end;

    ----------------------------------------------------------------------------
    function outside
    (
        a_version in semver_version,
        a_range   in semver_range,
        a_hilo    in semver_lexer.token_type
    ) return boolean is
        l_comp  semver_lexer.token_type;
        l_ecomp semver_lexer.token_type;
    
        function gtfn
        (
            a_this in semver_version,
            a_that in semver_version
        ) return boolean is
        begin
            if a_hilo = semver_lexer.tk_gt then
                return semver_version_impl.gt(a_this, a_that);
            else
                return semver_version_impl.lt(a_this, a_that);
            end if;
        end;
    
        function ltfn
        (
            a_this in semver_version,
            a_that in semver_version
        ) return boolean is
        begin
            if a_hilo = semver_lexer.tk_gt then
                return semver_version_impl.lt(a_this, a_that);
            else
                return semver_version_impl.gt(a_this, a_that);
            end if;
        end;
    
        function ltefn
        (
            a_this in semver_version,
            a_that in semver_version
        ) return boolean is
        begin
            if a_hilo = semver_lexer.tk_gt then
                return semver_version_impl.lte(a_this, a_that);
            else
                return semver_version_impl.gte(a_this, a_that);
            end if;
        end;
    
    begin
        d.log('outside hilo: "' || a_hilo || '" version: "' || a_version.to_string() || '" range: "' || a_range.to_string() || '"');
    
        d.log('checking hilo');
        case (a_hilo)
            when '>' then
                l_comp  := '>';
                l_ecomp := '>=';
            when '<' then
                l_comp  := '<';
                l_ecomp := '<=';
            else
                raise_application_error(-20000, 'Must provide a hilo val of "<" or ">"');
        end case;
        -- 
        if satisfies(a_version, a_range) then
            d.log('it satisifes the range it is not outside');
            return false;
        end if;
        --
        -- From now on, variable terms are as if we're in "gtr" mode.
        -- but note that everything is flipped for the "ltr" function.
        for i in 1 .. a_range.comparator_sets.count loop
            declare
                l_high       semver_comparator;
                l_low        semver_comparator;
                l_comparator semver_comparator;
            begin
                d.log('determine least and greatest comparators');
                for j in 1 .. a_range.comparator_sets(i).comparators.count loop
                    l_comparator := a_range.comparator_sets(i).comparators(j);
                    if l_comparator.version is null then
                        l_comparator := new semver_comparator('>=', semver_version(0, 0, 0));
                    end if;
                    l_high := nvl(l_high, l_comparator);
                    l_low  := nvl(l_low, l_comparator);
                
                    if (gtfn(l_comparator.version, l_high.version)) then
                        l_high := l_comparator;
                    elsif ltfn(l_comparator.version, l_low.version) then
                        l_low := l_comparator;
                    end if;
                end loop;
                d.log('low "' || l_low.to_string() || '"');
                d.log('high "' || l_high.to_string() || '"');
                --
                -- If the edge version comparator has a > || >= operator then our version
                -- isn't outside it
                if l_high.operator = l_comp or l_high.operator = l_ecomp then
                    d.log('edge version comparator has a > or >= operator then our version is not outside it');
                    d.log('version is not outside range from ' || a_hilo);
                    return false;
                end if;
                --
                -- If the lowest version comparator has an operator and our version
                -- is less than it then it isn't higher than the range
                if (l_low.operator is null or l_low.operator = l_comp) and ltefn(a_version, l_low.version) then
                    d.log('(l_low.operator is null or l_low.operator = l_comp) and ltefn(a_version, l_low.version)');
                    d.log('version is not outside range from ' || a_hilo);
                    return false;
                elsif l_low.operator = l_ecomp and ltfn(a_version, l_low.version) then
                    d.log('l_low.operator = l_ecomp and ltfn(a_version, l_low.version)');
                    d.log('version is not outside range from ' || a_hilo);
                    return false;
                end if;
            end;
        end loop;
        --
        d.log('version outside range from ' || a_hilo);
        return true;
        --    
    end;

end;
/
