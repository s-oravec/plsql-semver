create or replace package body semver_comparator_impl as

    d debug := new debug('semver:comparator');

    ----------------------------------------------------------------------------
    function test
    (
        a_this    in semver_comparator,
        a_version in semver_version
    ) return boolean is
        l_result boolean;
    begin
        -- NoFormat Start
        d.log('test "' 
              || case when a_version is not null then a_version.to_string() end
              || '" ' 
              || a_this.operator 
              || ' "' 
              || case when a_this.version is not null then a_this.version.to_string() end
              || '" ?');
        -- NoFormat End
        -- a_this = ANY
        if a_this.version is null then
            return true;
        end if;
    
        l_result := semver_version_impl.cmp(a_version, a_this.operator, a_this.version);
        d.log('test result: ' || semver_util.ternary_varchar2(l_result, 'true', 'false'));
        return l_result;
    end;

    ----------------------------------------------------------------------------
    function intersects
    (
        a_this  in semver_comparator,
        a_other in semver_comparator
    ) return boolean is
    begin
        --
        if a_this.operator is null then
            return semver_range_impl.satisfies(a_this.version, semver_range_impl.parse(a_other.version.to_string()));
        elsif a_other.operator is null then
            return semver_range_impl.satisfies(a_other.version, semver_range_impl.parse(a_this.version.to_string()));
        end if;
        -- NoFormat Start
        declare
            sameDirectionIncreasing       boolean
                := (a_this.operator = '>=' or a_this.operator = '>') and (a_other.operator = '>=' or a_other.operator = '>');
            sameDirectionDecreasing       boolean
                := (a_this.operator = '<=' or a_this.operator = '<') and (a_other.operator = '<=' or a_other.operator = '<');
            sameSemVer                    boolean
                := semver_version_impl.cmp(a_this.version, '=', a_other.version);
            differentDirectionsInclusive  boolean
                := (a_this.operator = '>=' or a_this.operator = '<=') and (a_other.operator = '>=' or a_other.operator = '<=');
            oppositeDirectionsLessThan    boolean
                := semver_version_impl.cmp(a_this.version, '<', a_other.version) 
                   and ((a_this.operator = '>=' or a_this.operator = '>') and (a_other.operator = '<=' or a_other.operator = '<'));
            oppositeDirectionsGreaterThan boolean
                := semver_version_impl.cmp(a_this.version, '>', a_other.version) 
                   and ((a_this.operator = '<=' or a_this.operator = '<') and (a_other.operator = '>=' or a_other.operator = '>'));
        begin
            return sameDirectionIncreasing 
                or sameDirectionDecreasing 
                or(sameSemVer and differentDirectionsInclusive) 
                or oppositeDirectionsLessThan 
                or oppositeDirectionsGreaterThan;
        end;
        -- NoFormat End
    end;

end;
/
