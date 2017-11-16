create or replace package body semver_version_impl as

    d debug := new debug('semver:version');

    ----------------------------------------------------------------------------  
    function compareIdentifiers
    (
        a_this  in varchar2,
        a_other in varchar2
    ) return semver.compare_result_type is
        l_this_is_number  boolean := regexp_like(a_this, semver_common.src(semver_common.IS_NUMERIC).expression);
        l_other_is_number boolean := regexp_like(a_other, semver_common.src(semver_common.IS_NUMERIC).expression);
        l_this            integer;
        l_other           integer;
    begin
        --
        if l_this_is_number and l_other_is_number then
            l_this  := to_number(a_this);
            l_other := to_number(a_other);
            -- NoFormat Start
            return 
                semver_util.ternary_pls_integer(l_this_is_number and not l_other_is_number, -1, 
                    semver_util.ternary_pls_integer(l_other_is_number and not l_this_is_number,  1, 
                        semver_util.ternary_pls_integer(l_this < l_other, -1,
                            semver_util.ternary_pls_integer(l_this > l_other,  1, 0)
                        )
                    )
                )
            ;
            -- NoFormat End
        else
            -- NoFormat Start
            return 
                semver_util.ternary_pls_integer(l_this_is_number and not l_other_is_number, -1, 
                    semver_util.ternary_pls_integer(l_other_is_number and not l_this_is_number,  1, 
                        semver_util.ternary_pls_integer(a_this < a_other, -1,
                            semver_util.ternary_pls_integer(a_this > a_other,  1, 0)
                        )
                    )
                )
            ;
            -- NoFormat End        
        end if;
    end;

    ----------------------------------------------------------------------------  
    function rcompareIdentifiers
    (
        a_this  in varchar2,
        a_other in varchar2
    ) return semver.compare_result_type is
    begin
        return compareIdentifiers(a_other, a_this);
    end;

    ----------------------------------------------------------------------------  
    function compareMain
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return semver.compare_result_type is
        l_cmp_major_result semver.compare_result_type;
        l_cmp_minor_result semver.compare_result_type;
    begin
        l_cmp_major_result := compareIdentifiers(a_this.major, a_other.major);
        if l_cmp_major_result = semver.COMPARE_RESULT_EQ then
            l_cmp_minor_result := compareIdentifiers(a_this.minor, a_other.minor);
            if l_cmp_minor_result = semver.COMPARE_RESULT_EQ then
                return compareIdentifiers(a_this.patch, a_other.patch);
            else
                return l_cmp_minor_result;
            end if;
        else
            return l_cmp_major_result;
        end if;
    end;

    ----------------------------------------------------------------------------  
    function comparePrerelease
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return semver.compare_result_type is
        l_this_has_prerelease  boolean := a_this.prerelease is not null and a_this.prerelease.count > 0;
        l_other_has_prerelease boolean := a_other.prerelease is not null and a_other.prerelease.count > 0;
        l_idx                  pls_integer := 1;
    begin
        d.log('this: ' || a_this.to_string());
        d.log('other: ' || a_other.to_string());
        --  // NOT having a prerelease is > having one
        if l_this_has_prerelease and not l_other_has_prerelease then
            d.log('l_this_has_prerelease and not l_other_has_prerelease');
            return semver.COMPARE_RESULT_LT;
        elsif not l_this_has_prerelease and l_other_has_prerelease then
            d.log('not l_this_has_prerelease and l_other_has_prerelease');
            return semver.COMPARE_RESULT_GT;
        elsif not l_this_has_prerelease and not l_other_has_prerelease then
            d.log('not l_this_has_prerelease and not l_other_has_prerelease');
            return semver.COMPARE_RESULT_EQ;
        end if;
        --
        loop        
            if l_idx > a_this.prerelease.count and l_idx > a_other.prerelease.count then                
                return semver.COMPARE_RESULT_EQ;
            elsif l_idx > a_other.prerelease.count then
                return semver.COMPARE_RESULT_GT;
            elsif l_idx > a_this.prerelease.count then
                return semver.COMPARE_RESULT_LT;
            elsif a_this.prerelease(l_idx) = a_other.prerelease(l_idx) then
                null;
            else
                return compareIdentifiers(a_this.prerelease(l_idx), a_other.prerelease(l_idx));
            end if;
            l_idx := l_idx + 1;
        end loop;
    end;

    ----------------------------------------------------------------------------  
    function compare
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return semver.compare_result_type is
        l_compareMainResult semver.compare_result_type;
    begin
        l_compareMainResult := compareMain(a_this, a_other);
        if l_compareMainResult = semver.COMPARE_RESULT_EQ then
            return comparePrerelease(a_this, a_other);
        else
            return l_compareMainResult;
        end if;
    end;

    ----------------------------------------------------------------------------  
    function rcompare
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return semver.compare_result_type is
    begin
        return compare(a_other, a_this);
    end;

    -- preminor will bump the version up to the next minor release, and immediately
    -- down to pre-release. premajor and prepatch work the same way.
    ----------------------------------------------------------------------------
    procedure inc
    (
        a_this       in out nocopy semver_version,
        a_release    in varchar2,
        a_identifier in varchar2
    ) is
    begin
        case a_release
            when 'premajor' then
                a_this.build      := new semver_tags();
                a_this.prerelease := new semver_tags();
                a_this.patch      := 0;
                a_this.minor      := 0;
                a_this.major      := a_this.major + 1;
                inc(a_this, 'pre', a_identifier);
            when 'preminor' then
                a_this.build      := new semver_tags();
                a_this.prerelease := new semver_tags();
                a_this.patch      := 0;
                a_this.minor      := a_this.minor + 1;
                inc(a_this, 'pre', a_identifier);
            when 'prepatch' then
                -- If this is already a prerelease, it will bump to the next version
                -- drop any prereleases that might already exist, since they are not
                -- relevant at this point.
                a_this.build      := new semver_tags();
                a_this.prerelease := new semver_tags();
                inc(a_this, 'patch', a_identifier);
                inc(a_this, 'pre', a_identifier);
            when 'prerelease' then
                -- If the input is a non-prerelease version, this acts the same as
                -- prepatch.
                if a_this.prerelease is null or a_this.prerelease.count = 0 then
                    inc(a_this, 'patch', a_identifier);
                end if;
                inc(a_this, 'pre', a_identifier);
            when 'major' then
                -- If this is a pre-major version, bump up to the same major version.
                -- Otherwise increment major.
                -- 1.0.0-5 bumps to 1.0.0
                -- 1.1.0 bumps to 2.0.0
                if a_this.minor != 0 or a_this.patch != 0 or a_this.prerelease is null or a_this.prerelease.count = 0 then
                    a_this.major := a_this.major + 1;
                end if;
                a_this.minor      := 0;
                a_this.patch      := 0;
                a_this.build      := new semver_tags();
                a_this.prerelease := new semver_tags();
            when 'minor' then
                -- If this is a pre-minor version, bump up to the same minor version.
                -- Otherwise increment minor.
                -- 1.2.0-5 bumps to 1.2.0
                -- 1.2.1 bumps to 1.3.0
                if a_this.patch != 0 or a_this.prerelease is null or a_this.prerelease.count = 0 then
                    a_this.minor := a_this.minor + 1;
                end if;
                a_this.patch      := 0;
                a_this.build      := new semver_tags();
                a_this.prerelease := new semver_tags();
            when 'patch' then
                -- If this is not a pre-release version, it will increment the patch.
                -- If it is a pre-release it will bump up to the same patch version.
                -- 1.2.0-5 patches to 1.2.0
                -- 1.2.0 patches to 1.2.1
                if a_this.prerelease is null or a_this.prerelease.count = 0 then
                    a_this.patch := a_this.patch + 1;
                end if;
                a_this.build      := new semver_tags();
                a_this.prerelease := new semver_tags();
            when 'pre' then
                -- This probably shouldn't be used publicly.
                -- 1.0.0 "pre" would become 1.0.0-0 which is the wrong direction.            
                if a_this.prerelease is null or a_this.prerelease.count = 0 then
                    a_this.prerelease := new semver_tags('0');
                else
                    declare
                        l_idx pls_integer := a_this.prerelease.count;
                    begin
                        while l_idx > 0 loop
                            if regexp_like(a_this.prerelease(l_idx), semver_common.src(semver_common.IS_NUMERIC).expression) then
                                a_this.prerelease(l_idx) := a_this.prerelease(l_idx) + 1;
                                l_idx := -1;
                            end if;
                            l_idx := l_idx - 1;
                        end loop;
                        if l_idx = 0 then
                            -- didn't increment anything
                            a_this.prerelease.extend();
                            a_this.prerelease(a_this.prerelease.count) := '0';
                        end if;
                    end;
                end if;
                if a_identifier is not null then
                    -- 1.2.0-beta.1 bumps to 1.2.0-beta.2,
                    -- 1.2.0-beta.fooblz or 1.2.0-beta bumps to 1.2.0-beta.0
                    if a_this.prerelease(1) = a_identifier then
                        if not regexp_like(a_this.prerelease(2), semver_common.src(semver_common.IS_NUMERIC).expression) then
                            a_this.prerelease := new semver_tags(a_identifier, '0');
                        end if;
                    else
                        a_this.prerelease := new semver_tags(a_identifier, '0');
                    end if;
                end if;
            else
                raise_application_error(-20000, 'Invalid increment argument "' || a_release || '"');
        end case;
    end;

    ----------------------------------------------------------------------------
    function gt
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return boolean is
    begin
        return compare(a_this, a_other) = semver.COMPARE_RESULT_GT;
    end;

    ----------------------------------------------------------------------------
    function lt
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return boolean is
    begin
        return compare(a_this, a_other) = semver.COMPARE_RESULT_LT;
    end;

    ----------------------------------------------------------------------------
    function eq
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return boolean is
    begin
        return compare(a_this, a_other) = semver.COMPARE_RESULT_EQ;
    end;

    ----------------------------------------------------------------------------
    function neq
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return boolean is
    begin
        return compare(a_this, a_other) != semver.COMPARE_RESULT_EQ;
    end;

    ----------------------------------------------------------------------------
    function gte
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return boolean is
    begin
        return compare(a_this, a_other) in(semver.COMPARE_RESULT_GT, semver.COMPARE_RESULT_EQ);
    end;

    ----------------------------------------------------------------------------
    function lte
    (
        a_this  in semver_version,
        a_other in semver_version
    ) return boolean is
    begin
        return compare(a_this, a_other) in(semver.COMPARE_RESULT_LT, semver.COMPARE_RESULT_EQ);
    end;

    ---------------------------------------------------------------------------- 
    function cmp
    (
        a_this  in semver_version,
        a_op    in varchar2,
        a_other in semver_version
    ) return boolean is
    begin
        case nvl(a_op, '<null>')
            when '===' then
                -- if (typeof a === 'object') a = a.version;
                -- if (typeof b === 'object') b = b.version;
                return a_this.format = a_other.format;
            when '!==' then
                -- if (typeof a === 'object') a = a.version;
                -- if (typeof b === 'object') b = b.version;
                return a_this.format != a_other.format;
            when '<null>' then
                return eq(a_this, a_other);
            when '=' then
                return eq(a_this, a_other);
            when '==' then
                return eq(a_this, a_other);
            when '!=' then
                return neq(a_this, a_other);
            when '>' then
                return gt(a_this, a_other);
            when '>=' then
                return gte(a_this, a_other);
            when '<' then
                return lt(a_this, a_other);
            when '<=' then
                return lte(a_this, a_other);
            else
                raise_application_error(-20000, 'Invalid operator: "' || a_op || '"');
        end case;
    end;

    ----------------------------------------------------------------------------
    function parse(a_value in varchar2) return semver_version is
        l_result                semver_version;
        l_semverParts           semver_tags;
        l_fullversionExpression semver_common.typ_regexp_expression := semver_common.src(semver_common.FULLVERSION).expression;
        l_fullversionModifier   semver_common.typ_regexp_modifier := semver_common.src(semver_common.FULLVERSION).modifier;
    
        function parse_suffix
        (
            a_value             in varchar2,
            a_identifier_regexp in semver_common.typ_regexp_name
        ) return semver_tags is
            l_result semver_tags;
            e_divide_by_zero exception;
            pragma exception_init(e_divide_by_zero, -1476);
            l_expression semver_common.typ_regexp_expression := semver_common.src(a_identifier_regexp).expression;
        begin
            -- NoFormat Start
            with identifier as
             (select semver_util.value_at_position(a_value, '.', level) as value from dual connect by level <= regexp_count(a_value, '\.') + 1)
            select value bulk collect into l_result
              from identifier
             where -- raise exception when value is not numeric or nonnumeric identifier
                   1 / case when regexp_like(value, '^' || l_expression || '$') then 1 else 0 end = 1;
            -- noformat end
            return l_result;
        exception
            when e_divide_by_zero then
                raise_application_error(-20000, 'Invalid ' || a_identifier_regexp || ' specified: "' || a_Value || '"');
        end;
    
    begin
        d.log('parsing value "' || a_value || '"');
        -- validate
        if length(a_value) > semver_common.MAX_LENGTH then
            raise_application_error(-20000, 'Value too long.');
        end if;
        --
        if regexp_like(a_value,
                       semver_common.src(semver_common.FULLVERSION).expression,
                       semver_common.src(semver_common.FULLVERSION).modifier) then
            d.log('value satisfies FULLVERSION regexp');
            -- strip (v|=|\s) and \s* from end
            select value
              bulk collect
              into l_semverParts
              from (select regexp_substr(a_value, l_fullversionExpression, 1, 1, l_fullversionModifier, N) as value
                      from dual, (select level as N from dual connect by level <= 5))
             where regexp_like(value, '[0-9]+') -- major, minor, patch
                or value like '-%' -- prerelease
                or value like '+%' -- build
            ;
            --
            l_result := new semver_version(major => to_number(l_semverParts(1)),
                                           minor => to_number(l_semverParts(2)),
                                           patch => to_number(l_semverParts(3)));
            --
            if l_semverParts.count > 3 then
                if l_semverParts(4) like '-%' then
                    d.log('parsing prerelease "' || l_semverParts(4) || '"');
                    l_result.prerelease := parse_suffix(substr(l_semverParts(4), 2), semver_common.PRERELEASEIDENTIFIER);
                else
                    d.log('parsing build "' || l_semverParts(4) || '"');
                    l_result.build := parse_suffix(substr(l_semverParts(4), 2), semver_common.BUILDIDENTIFIER);
                end if;
            end if;
            --
            if l_semverParts.count > 4 then
                d.log('parsing build "' || l_semverParts(5) || '"');
                l_result.build := parse_suffix(substr(l_semverParts(5), 2), semver_common.BUILDIDENTIFIER);
            end if;
            --
            d.log('successfully parsed');
            return l_result;
            --
        else
            d.log('does not satisy FULLVERSION regexp');
            raise_application_error(-20000, 'Invalid SemVer string "' || a_value || '"');
        end if;
        --
    exception
        when others then
            d.log('exception: ' || sqlerrm);
            raise_application_error(-20000, 'Invalid SemVer string "' || a_value || '"' || chr(10) || sqlerrm);
    end;

    ----------------------------------------------------------------------------  
    function to_string(a_semver in semver_version) return varchar2 is
    begin
        -- NoFormat Start
        return
            a_semver.major || '.' ||
            a_semver.minor || '.' ||
            a_semver.patch ||
            semver_util.ternary_varchar2(
                a_semver.prerelease is not null and a_semver.prerelease.count > 0,
                '-' || semver_util.join_semver_tags(a_semver.prerelease, '.')
            ) ||
            semver_util.ternary_varchar2(
                a_semver.build is not null and a_semver.build.count > 0,
                '+' || semver_util.join_semver_tags(a_semver.build, '.')
            )
        ;
        -- NoFormat End
    end;

    ----------------------------------------------------------------------------
    function valid(a_value in varchar2) return varchar2 is
        l_semver semver_version;
    begin
        d.log('validating value> ' || a_value);
        <<try_parse_version>>
        begin
            l_semver := parse(a_value);
            d.log('value is valid semver string');
            return to_string(l_semver);
        exception
            when others then
                d.log('value is not valid semver string > return null');
                return null;
        end try_parse_version;
    end;

    ----------------------------------------------------------------------------
    function clean(a_value in varchar2) return varchar2 is
    begin
        return valid(regexp_replace(a_value, '^[=v]+', ''));
    end;

end;
/
