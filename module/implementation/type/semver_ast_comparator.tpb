create or replace type body semver_ast_comparator as

    ----------------------------------------------------------------------------
    constructor function semver_ast_comparator
    (
        type    in varchar2,
        oper    in varchar2,
        partial in semver_ast_partial
    ) return self as result is
    begin
        -- validate
        if partial is null then
            -- partial cannot be null > raise
            raise_application_error(-20000, 'Partial not set for comparator.');
        end if;
        --
        self.symbol_type := semver_range_parser.ast_Comparator;
        --
        self.type    := type;
        self.oper    := oper;
        self.partial := partial;
        --
        return;
    end;

    ----------------------------------------------------------------------------
    static function createNew
    (
        type    in varchar2,
        oper    in varchar2,
        partial in semver_ast_partial
    ) return semver_ast_comparator is
        l_Result semver_ast_comparator;
    begin
        l_Result := new semver_ast_comparator(type, oper, partial);
        semver_ast_registry.register(l_Result);
        return l_Result;
    end;

    ----------------------------------------------------------------------------
    overriding member function toString return varchar2 is
    begin
        return '{ast:' || self.symbol_type || ',type:' || self.type || ',oper:' || self.oper || ',partial:' || self.partial.toString() || '}';
    end;

    ----------------------------------------------------------------------------  
    member function get_primitve_comparators return semver_comparators is
    
        p             semver_ast_partial := self.partial;
        d             debug := new debug('semver:parser:translate');
        l_log_message varchar2(4000);
        l_result      semver_comparators := semver_comparators();
    
        ----------------------------------------------------------------------------  
        function isX(identifier varchar2) return boolean is
        begin
            return identifier in('x', 'X', '*');
        end;
    
        ----------------------------------------------------------------------------  
        procedure append_result(a_comparator in semver_comparator) is
        begin
            l_result.extend();
            l_result(l_result.last) := a_comparator;
        end;
    
        -- ~, ~> --> * (any, kinda silly)
        -- ~2, ~2.x, ~2.x.x, ~>2, ~>2.x ~>2.x.x --> >=2.0.0 <3.0.0
        -- ~2.0, ~2.0.x, ~>2.0, ~>2.0.x --> >=2.0.0 <2.1.0
        -- ~1.2, ~1.2.x, ~>1.2, ~>1.2.x --> >=1.2.0 <1.3.0
        -- ~1.2.3, ~>1.2.3 --> >=1.2.3 <1.3.0
        -- ~1.2.0, ~>1.2.0 --> >=1.2.0 <1.3.0
        ----------------------------------------------------------------------------  
        procedure translate_tilde_to_primitives as
        begin
            d.log('tilde: ' || p.toString());
            if isX(p.major) then
                d.log('major is *');
                null;
            elsif isX(p.minor) then
                d.log('minor is *');
                append_result(semver_comparator('>=', semver_version(p.major, 0, 0)));
                append_result(semver_comparator('<', semver_version(p.major + 1, 0, 0)));
            elsif isX(p.patch) then
                d.log('patch is *');
                append_result(semver_comparator('>=', semver_version(p.major, p.minor, 0)));
                append_result(semver_comparator('<', semver_version(p.major, p.minor + 1, 0)));
            elsif p.prerelease is not null then
                d.log('tilde to primitive prerelease: ' || p.prerelease.toString());
                append_result(semver_comparator('>=', semver_version(p.major, p.minor, p.patch, p.prerelease.tags)));
                append_result(semver_comparator('<', semver_version(p.major, p.minor + 1, 0)));
            else
                d.log('else');
                append_result(semver_comparator('>=', semver_version(p.major, p.minor, p.patch)));
                append_result(semver_comparator('<', semver_version(p.major, p.minor + 1, 0)));
            end if;
            --
            l_log_message := 'tilde return:';
            --
        end;
    
        -- ^ --> * (any, kinda silly)
        -- ^2, ^2.x, ^2.x.x --> >=2.0.0 <3.0.0
        -- ^2.0, ^2.0.x --> >=2.0.0 <3.0.0
        -- ^1.2, ^1.2.x --> >=1.2.0 <2.0.0
        -- ^1.2.3 --> >=1.2.3 <2.0.0
        -- ^1.2.0 --> >=1.2.0 <2.0.0
        ----------------------------------------------------------------------------  
        procedure translate_caret_to_primitives is
        begin
            d.log('caret: ' || p.toString());
            if isX(p.major) then
                d.log('major is *');
                null;
            elsif isX(p.minor) then
                d.log('minor is *');
                append_result(semver_comparator('>=', semver_version(p.major, 0, 0)));
                append_result(semver_comparator('<', semver_version(p.major + 1, 0, 0)));
            elsif isX(p.patch) then
                if p.major = '0' then
                    d.log('patch is * and major is 0');
                    append_result(semver_comparator('>=', semver_version(p.major, p.minor, 0)));
                    append_result(semver_comparator('<', semver_version(p.major, p.minor + 1, 0)));
                else
                    d.log('patch is * and major is not 0');
                    append_result(semver_comparator('>=', semver_version(p.major, p.minor, 0)));
                    append_result(semver_comparator('<', semver_version(p.major + 1, 0, 0)));
                end if;
            elsif p.prerelease is not null then
                d.log('caret to primitive prerelease: ' || p.prerelease.toString());
                if p.major = '0' then
                    d.log('major is 0');
                    if p.minor = '0' then
                        d.log('minor is 0');
                        append_result(semver_comparator('>=', semver_version(p.major, p.minor, p.patch, p.prerelease.tags)));
                        append_result(semver_comparator('<', semver_version(p.major, p.minor, p.patch + 1)));
                    else
                        d.log('minor is not');
                        append_result(semver_comparator('>=', semver_version(p.major, p.minor, p.patch, p.prerelease.tags)));
                        append_result(semver_comparator('<', semver_version(p.major, p.minor + 1, 0)));
                    end if;
                else
                    d.log('major is not 0');
                    append_result(semver_comparator('>=', semver_version(p.major, p.minor, p.patch, p.prerelease.tags)));
                    append_result(semver_comparator('<', semver_version(p.major + 1, 0, 0)));
                end if;
            else
                d.log('no prerelease');
                if p.major = '0' then
                    if p.minor = '0' then
                        append_result(semver_comparator('>=', semver_version(p.major, p.minor, p.patch)));
                        append_result(semver_comparator('<', semver_version(p.major, p.minor, p.patch + 1)));
                    else
                        append_result(semver_comparator('>=', semver_version(p.major, p.minor, p.patch)));
                        append_result(semver_comparator('<', semver_version(p.major, p.minor + 1, 0)));
                    end if;
                else
                    append_result(semver_comparator('>=', semver_version(p.major, p.minor, p.patch)));
                    append_result(semver_comparator('<', semver_version(p.major + 1, 0, 0)));
                end if;
            end if;
            --
            l_log_message := 'caret return:';
            --
        end;
    
        ----------------------------------------------------------------------------  
        procedure translate_primitive is
            l_xmajor boolean := isX(p.major);
            l_xminor boolean := l_xmajor or isX(p.minor);
            l_xpatch boolean := l_xminor or isX(p.patch);
            l_anyx   boolean := l_xpatch;
            l_gtlt   varchar2(2) := self.oper;
            l_major pls_integer := case
                                       when regexp_like(p.major, '^[0-9]+$') then
                                        p.major
                                   end;
            l_minor pls_integer := case
                                       when regexp_like(p.minor, '^[0-9]+$') then
                                        p.minor
                                   end;
            l_patch pls_integer := case
                                       when regexp_like(p.patch, '^[0-9]+$') then
                                        p.patch
                                   end;
        begin
            if l_gtlt = '=' and l_anyx then
                l_gtlt := '';
            end if;
        
            if l_xmajor then
                if l_gtlt = '>' or l_gtlt = '<' then
                    -- nothing is allowed
                    append_result(semver_comparator('<', semver_version(0, 0, 0)));
                else
                    -- everything is possible
                    append_result(semver_comparator('*', null));
                end if;
            elsif l_gtlt is not null and l_anyX then
                -- replace x with 0                
                if l_xminor then
                    l_minor := 0;
                end if;
                if l_xpatch then
                    l_patch := 0;
                end if;
            
                if l_gtlt = '>' then
                    -- >1 => >=2.0.0
                    -- >1.2 => >=1.3.0
                    -- >1.2.3 => >= 1.2.4
                    l_gtlt := '>=';
                    if l_xminor then
                        l_major := l_major + 1;
                        l_minor := 0;
                        l_patch := 0;
                    elsif l_xpatch then
                        l_minor := l_minor + 1;
                        l_patch := 0;
                    end if;
                elsif l_gtlt = '<=' then
                    -- <=0.7.x is actually <0.8.0, since any 0.7.x should
                    -- pass.  Similarly, <=7.x is actually <8.0.0, etc.
                    l_gtlt := '<';
                    if l_xminor then
                        l_major := l_major + 1;
                    else
                        l_minor := l_minor + 1;
                    end if;
                end if;
            
                append_result(semver_comparator(l_gtlt, semver_version(l_major, l_minor, l_patch)));
            elsif l_xminor then
                append_result(semver_comparator('>=', semver_version(l_major, 0, 0)));
                append_result(semver_comparator('<', semver_version(l_major + 1, 0, 0)));
            elsif l_xpatch then
                append_result(semver_comparator('>=', semver_version(l_major, l_minor, 0)));
                append_result(semver_comparator('<', semver_version(l_major, l_minor + 1, 0)));
            else
                if l_gtlt = '=' then
                    l_gtlt := '';
                end if;
                append_result(semver_comparator(l_gtlt, semver_version(l_major, l_minor, l_patch)));
            end if;
            --
            l_log_message := 'primitive return:';
            --
        end;
    
    begin
        case self.type
            when semver_range_parser.COMPARATOR_TYPE_TILDE then
                translate_tilde_to_primitives;
            when semver_range_parser.COMPARATOR_TYPE_CARET then
                translate_caret_to_primitives;
            else
                -- replace XRange
                translate_primitive;
        end case;
        --
        -- debug       
        for i in 1 .. l_result.count loop
            l_log_message := l_log_message || ' ' || l_result(i).to_string();
        end loop;
        --
        d.log(l_log_message);
        --
        return l_result;
        --
    end;

end;
/
