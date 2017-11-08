create or replace package body semver as

    ----------------------------------------------------------------------------
    function parse(value in varchar2) return semver_version is
    begin
        if length(value) > semver_common.MAX_LENGTH then
            return null;
        end if;
        return semver_version(value);
    exception
        when others then
            return null;
    end;

    ----------------------------------------------------------------------------
    function diff
    (
        version1 in varchar2,
        version2 in varchar2
    ) return varchar2 is
    begin
        if version1 = version2 then
            return null;
        else
            declare
                l_this  semver_version := parse(version1);
                l_other semver_version := parse(version2);
            begin
                if (l_this.prerelease is not null and l_this.prerelease.count > 0) or
                   (l_other.prerelease is not null and l_other.prerelease.count > 0) then
                    if l_this.major != l_other.major then
                        return 'premajor';
                    elsif l_this.minor != l_other.minor then
                        return 'preminor';
                    elsif l_this.patch != l_other.patch then
                        return 'prepatch';
                    else
                        return 'prerelease';
                    end if;
                end if;
            
                if l_this.major != l_other.major then
                    return 'major';
                elsif l_this.minor != l_other.minor then
                    return 'minor';
                elsif l_this.patch != l_other.patch then
                    return 'patch';
                else
                    raise_application_error(-20000, 'Wait what?');
                end if;
            end;
        end if;
    end;

    ----------------------------------------------------------------------------
    function major(value in varchar2) return varchar2 is
        l_this semver_version;
    begin
        l_this := parse(value);
        if l_this is not null then
            return l_this.major;
        else
            return null;
        end if;
    end;

    ----------------------------------------------------------------------------
    function minor(value in varchar2) return varchar2 is
        l_this semver_version;
    begin
        l_this := parse(value);
        if l_this is not null then
            return l_this.minor;
        else
            return null;
        end if;
    end;

    ----------------------------------------------------------------------------
    function patch(value in varchar2) return varchar2 is
        l_this semver_version;
    begin
        l_this := parse(value);
        if l_this is not null then
            return l_this.patch;
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

        
    -- gt lt gte lte eq neq
    -- cmp

    ----------------------------------------------------------------------------
    function inc
    (
        value      in varchar2,
        release    in varchar2,
        identifier in varchar2 default null
    ) return varchar2 is
        l_semver semver_version;
    begin
        l_semver := new semver_version(value);
        l_semver.inc(release, identifier);
        return l_semver.to_string();
        return semver_version_impl.inc(value, release, identifier);
    end;

    ----------------------------------------------------------------------------
    function valid(value in varchar2) return varchar2 is
    begin
        return semver_version_impl.valid(value);
    end;

    ----------------------------------------------------------------------------
    function clean(value in varchar2) return varchar2 is
    begin
        return semver_version_impl.clean(value);
    end;

end;
/
