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
    begin
        if a_version is null then
            return false;
        else
            for i in 1 .. a_range.comparators.count loop
                if not semver_Comparator_impl.test(a_range.comparators(i), a_version) then
                    return false;
                end if;
            end loop;
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

end;
/
