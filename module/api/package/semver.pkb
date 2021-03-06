create or replace package body semver as

    d debug := new debug('semver');

    ----------------------------------------------------------------------------
    function parse(version in varchar2) return semver_version is
    begin
        return semver_version_impl.parse(version);
    exception
        when others then
            return null;
    end;

    ----------------------------------------------------------------------------
    function diff
    (
        version1 in varchar2,
        version2 in varchar2
    ) return release_type is
    begin
        if version1 = version2 then
            return null;
        else
            declare
                l_this  semver_version := parse(version1);
                l_other semver_version := parse(version2);
            begin
                if l_this = l_other then
                    return null;
                end if;
                if (l_this.prerelease is not null and l_this.prerelease.count > 0) or
                   (l_other.prerelease is not null and l_other.prerelease.count > 0) then
                    if l_this.major != l_other.major then
                        return semver.RELEASE_PREMAJOR;
                    elsif l_this.minor != l_other.minor then
                        return semver.RELEASE_PREMINOR;
                    elsif l_this.patch != l_other.patch then
                        return semver.RELEASE_PREPATCH;
                    else
                        return semver.RELEASE_PRERELEASE;
                    end if;
                end if;
            
                if l_this.major != l_other.major then
                    return semver.RELEASE_MAJOR;
                elsif l_this.minor != l_other.minor then
                    return semver.RELEASE_MINOR;
                elsif l_this.patch != l_other.patch then
                    return semver.RELEASE_PATCH;
                else
                    raise_application_error(-20000, 'Wait what?');
                end if;
            end;
        end if;
    end;

    ----------------------------------------------------------------------------
    function major(version in varchar2) return pls_integer is
        l_this semver_version;
    begin
        l_this := parse(version);
        if l_this is not null then
            return l_this.major;
        else
            return null;
        end if;
    end;

    ----------------------------------------------------------------------------
    function minor(version in varchar2) return pls_integer is
        l_this semver_version;
    begin
        l_this := parse(version);
        if l_this is not null then
            return l_this.minor;
        else
            return null;
        end if;
    end;

    ----------------------------------------------------------------------------
    function patch(version in varchar2) return pls_integer is
        l_this semver_version;
    begin
        l_this := parse(version);
        if l_this is not null then
            return l_this.patch;
        else
            return null;
        end if;
    end;

    ----------------------------------------------------------------------------
    function prerelease(version in varchar2) return semver_tags is
        l_this semver_version;
    begin
        l_this := parse(version);
        if l_this is not null then
            return l_this.prerelease;
        else
            return null;
        end if;
    end;

    ----------------------------------------------------------------------------
    function build(version in varchar2) return semver_tags is
        l_this semver_version;
    begin
        l_this := parse(version);
        if l_this is not null then
            return l_this.build;
        else
            return null;
        end if;
    end;

    ----------------------------------------------------------------------------
    function compare
    (
        version1 in varchar2,
        version2 in varchar2
    ) return compare_result_type is
        l_this  semver_version := parse(version1);
        l_other semver_version := parse(version2);
    begin
        return l_this.compare(l_other);
    end;

    ----------------------------------------------------------------------------
    function rcompare
    (
        version1 in varchar2,
        version2 in varchar2
    ) return compare_result_type is
        l_this  semver_version := parse(version1);
        l_other semver_version := parse(version2);
    begin
        return l_other.compare(l_this);
    end;

    ----------------------------------------------------------------------------
    function compareIdentifiers
    (
        identifier1 in varchar2,
        identifier2 in varchar2
    ) return compare_result_type is
    begin
        return semver_version_impl.compareIdentifiers(identifier1, identifier2);
    end;

    ----------------------------------------------------------------------------
    function rcompareIdentifiers
    (
        identifier1 in varchar2,
        identifier2 in varchar2
    ) return compare_result_type is
    begin
        return semver_version_impl.rcompareIdentifiers(identifier1, identifier2);
    end;

    ----------------------------------------------------------------------------
    procedure sort_impl
    (
        a_semver_version_table in out nocopy semver_version_table_type,
        a_reverse              in boolean
    ) is
        l_tmp semver_version;
    begin
        if a_semver_version_table is null or a_semver_version_table.count <= 1 then
            return;
        else
            -- doesn't need to be superfast or supercool or what > bubblesort
            for i in 1 .. a_semver_version_table.count - 1 loop
                for j in i + 1 .. a_semver_version_table.count loop
                    if (not a_reverse and a_semver_version_table(i).compare(a_semver_version_table(j)) = COMPARE_RESULT_GT) or
                       (a_reverse and a_semver_version_table(i).compare(a_semver_version_table(j)) = COMPARE_RESULT_LT) then
                        -- swap
                        l_tmp := a_semver_version_table(i);
                        a_semver_version_table(i) := a_semver_version_table(j);
                        a_semver_version_table(j) := l_tmp;
                    end if;
                end loop;
            end loop;
        end if;
    end;

    ----------------------------------------------------------------------------  
    function convert_to_semver_version_tab(semver_string_table in semver_string_table_type) return semver_version_table_type is
        l_result semver_version_table_type;
        l_tmp    semver_version;
    begin
        if semver_string_table is null or semver_string_table.count = 0 then
            return new semver_version_table_type();
        else
            for i in 1 .. semver_string_table.count loop
                l_tmp := parse(semver_string_table(i));
                if l_tmp is not null then
                    l_result.extend();
                    l_result(l_result.last) := l_tmp;
                end if;
            end loop;
            return l_result;
        end if;
    end;

    ----------------------------------------------------------------------------  
    procedure sort_semver_string_table_impl
    (
        semver_string_table in out nocopy semver_string_table_type,
        a_reverse           in boolean
    ) is
        l_semver_version_table semver_version_table_type;
    begin
        -- null > null, empty > empty
        if semver_string_table is null or semver_string_table.count = 0 then
            return;
        end if;
        -- convert to semver_version table
        l_semver_version_table := convert_to_semver_version_tab(semver_string_table);
        -- sort
        sort_impl(l_semver_version_table, a_reverse);
        -- delete items in collection
        semver_string_table.delete;
        -- append
        if l_semver_version_table.count > 0 then
            semver_string_table.extend(l_semver_version_table.count);
            for i in 1 .. l_semver_version_table.count loop
                semver_string_table(i) := l_semver_version_table(i).to_string();
            end loop;
        end if;
    end;

    ----------------------------------------------------------------------------  
    procedure sort(semver_version_table in out nocopy semver_version_table_type) is
    begin
        sort_impl(semver_version_table, false);
    end;

    ----------------------------------------------------------------------------  
    procedure sort(semver_string_table in out nocopy semver_string_table_type) is
    begin
        sort_semver_string_table_impl(semver_string_table, false);
    end;

    ----------------------------------------------------------------------------  
    procedure rsort(semver_version_table in out nocopy semver_version_table_type) is
    begin
        sort_impl(semver_version_table, true);
    end;

    ----------------------------------------------------------------------------  
    procedure rsort(semver_string_table in out nocopy semver_string_table_type) is
    begin
        sort_semver_string_table_impl(semver_string_table, true);
    end;

    ----------------------------------------------------------------------------
    function gt
    (
        version1 in varchar2,
        version2 in varchar2
    ) return boolean is
    begin
        return semver_version_impl.gt(parse(version1), parse(version2));
    end;

    ----------------------------------------------------------------------------
    function lt
    (
        version1 in varchar2,
        version2 in varchar2
    ) return boolean is
    begin
        return semver_version_impl.lt(parse(version1), parse(version2));
    end;

    ----------------------------------------------------------------------------
    function eq
    (
        version1 in varchar2,
        version2 in varchar2
    ) return boolean is
    begin
        return semver_version_impl.eq(parse(version1), parse(version2));
    end;

    ----------------------------------------------------------------------------
    function neq
    (
        version1 in varchar2,
        version2 in varchar2
    ) return boolean is
    begin
        return semver_version_impl.neq(parse(version1), parse(version2));
    end;

    ----------------------------------------------------------------------------
    function gte
    (
        version1 in varchar2,
        version2 in varchar2
    ) return boolean is
    begin
        return semver_version_impl.gte(parse(version1), parse(version2));
    end;

    ----------------------------------------------------------------------------
    function lte
    (
        version1 in varchar2,
        version2 in varchar2
    ) return boolean is
    begin
        return semver_version_impl.lte(parse(version1), parse(version2));
    end;

    ----------------------------------------------------------------------------
    function cmp
    (
        version1 in varchar2,
        operator in varchar2,
        version2 in varchar2
    ) return boolean is
        l_version1 semver_version := parse(version1);
        l_version2 semver_version := parse(version2);
    begin
        return semver_version_impl.cmp(l_version1, operator, l_version2);
    end;

    ----------------------------------------------------------------------------
    function inc
    (
        version    in varchar2,
        release    in release_type,
        identifier in varchar2 default null
    ) return varchar2 is
        l_semver semver_version;
    begin
        l_semver := new semver_version(version);
        if l_semver is not null then
            l_semver.inc(release, identifier);
            return l_semver.to_string();
        else
            return null;
        end if;
    exception
        when others then
            return null;
    end;

    ----------------------------------------------------------------------------
    function valid(version in varchar2) return varchar2 is
    begin
        return semver_version_impl.valid(version);
    end;

    ----------------------------------------------------------------------------
    function clean(version in varchar2) return varchar2 is
    begin
        return semver_version_impl.clean(version);
    end;

    ----------------------------------------------------------------------------  
    function satisfies
    (
        version in varchar2,
        range   in varchar2
    ) return boolean is
    begin
        return semver_range_impl.satisfies(parse(version), parse_range(range));
    end;

    ----------------------------------------------------------------------------
    function intersects
    (
        range1 in varchar2,
        range2 in varchar2
    ) return boolean is
        l_range1 semver_range;
        l_range2 semver_range;
    begin
        l_range1 := parse_range(range1);
        l_range2 := parse_range(range2);
        --
        return semver_range_impl.intersects(l_range1, l_range2);
    end;

    ----------------------------------------------------------------------------
    function parse_range(range in varchar2) return semver_range is
        l_range semver_range;
    begin
        l_range := semver_range_impl.parse(range);
        if l_range is null then
            return null;
        else
            return l_range;
        end if;
    exception
        when others then
            return null;
    end;

    ----------------------------------------------------------------------------
    function valid_range(range in varchar2) return varchar2 is
        l_range semver_range;
    begin
        l_range := parse_range(range);
        if l_range is not null then
            return l_range.to_string();
        else
            return null;
        end if;
    end;

    ----------------------------------------------------------------------------
    function satisfying
    (
        versions           in semver_string_table_type,
        range              in varchar2,
        aggregate_function in semver_range_impl.aggregate_function_type
    ) return varchar2 is
        l_versions semver_versions;
        l_range    semver_range;
        l_result   semver_version;
    begin
        -- try parse vesions
        if versions is null or versions.count = 0 then
            d.log('satisfying is null when versions is empty or null');
            return null;
        else
            d.log('parse versions');
            l_versions := semver_versions();
            for i in 1 .. versions.count loop
                declare
                    l_version semver_version := parse(versions(i));
                begin
                    if l_version is not null then
                        l_versions.extend();
                        l_versions(l_versions.count) := l_version;
                    end if;
                end;
            end loop;
            --
            if l_versions.count = 0 then
                d.log('no version left after parse attempts');
                return null;
            end if;
        end if;
        d.log('try parse range');
        l_range := parse_range(range);
        if l_range is not null then
            l_result := semver_range_impl.satisfying(l_versions, l_range, aggregate_function);
            if l_result is null then
                d.log('satisfying is null');
                return null;
            else
                d.log('return ' || l_result.to_string());
                return l_result.to_string();
            end if;
        else
            d.log('parsing range failed');
            return null;
        end if;
    end;

    ----------------------------------------------------------------------------
    function max_satisfying
    (
        versions in semver_string_table_type,
        range    in varchar2
    ) return varchar2 is
    begin
        return satisfying(versions, range, semver_range_impl.FN_MAX);
    end;

    ----------------------------------------------------------------------------
    function min_satisfying
    (
        versions in semver_string_table_type,
        range    in varchar2
    ) return varchar2 is
    begin
        return satisfying(versions, range, semver_range_impl.FN_MIN);
    end;

    ----------------------------------------------------------------------------  
    function outside
    (
        a_version in varchar2,
        a_range   in varchar2,
        a_hilo    in semver_lexer.token_type
    ) return boolean is
        l_version semver_version;
        l_range   semver_range;
    begin
        l_range   := parse_range(a_range);
        l_version := parse(a_version);
        if l_range is null or l_version is null then
            return false;
        else
            return semver_range_impl.outside(l_version, l_range, a_hilo);
        end if;
    end;

    ----------------------------------------------------------------------------
    function gtr
    (
        version in varchar2,
        range   in varchar2
    ) return boolean is
    begin
        return outside(version, range, semver_lexer.tk_gt);
    end;

    ----------------------------------------------------------------------------  
    function ltr
    (
        version in varchar2,
        range   in varchar2
    ) return boolean is
    begin
        return outside(version, range, semver_lexer.tk_lt);
    end;

end;
/
