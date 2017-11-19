create or replace package body semver_range_parser as

    d debug := new debug('semver:range_parser');

    ----------------------------------------------------------------------------
    procedure initialize(a_value in varchar2) is
        l_value varchar2(255);
    begin
        d.log('initializing with: "' || a_value || '"');
        d.log('stripping excesive spaces, ~> -> ~');
        l_value := regexp_replace(a_value, '(>|>=|<|<=|~|=|\^|~)\s*v?\s*', '\1');
        l_value := regexp_replace(l_value, '\s+', ' ');
        l_value := regexp_replace(l_value, '~>', '~');
        d.log('stripped excesive white space: "' || l_value || '"');
        semver_token_stream.initialize(l_value);
    exception
        when others then
            d.log('intialize exception: ' || sqlerrm);
    end;

    ----------------------------------------------------------------------------  
    procedure appendToList
    (
        ast      in semver_ast,
        children in out nocopy semver_ASTChildren
    ) is
    begin
        if ast is not null then
            children.extend();
            children(children.last) := ast.id_registry;
        end if;
    end;

    ----------------------------------------------------------------------------  
    function appendToList
    (
        ast      in semver_ast,
        children in out nocopy semver_ASTChildren
    ) return boolean is
    begin
        if ast is not null then
            children.extend();
            children(children.last) := ast.id_registry;
            return true;
        end if;
        return false;
    end;

    ----------------------------------------------------------------------------
    function currentTokenType return semver_lexer.token_type is
    begin
        return semver_token_stream.currentToken().tokenType;
    end;

    ---------------------------------------------------------------------------- 
    function currentTokenTypeIs(tokeType semver_lexer.token_type) return boolean is
    begin
        return semver_token_stream.currentToken().tokenType = tokeType;
    end;

    ----------------------------------------------------------------------------
    function currentTokenText return varchar2 is
    begin
        return semver_token_stream.currentToken().text;
    end;

    ----------------------------------------------------------------------------
    function currentTokenInfo return varchar2 is
    begin
        return semver_util.ternary_varchar2(currentTokenText is null, currentTokenType, currentTokenText);
    end;

    ----------------------------------------------------------------------------
    procedure raiseUnexpectedToken(tokenType in semver_lexer.token_type) is
    begin
        raise_application_error(-20000,
                                'Unexpected token ' || tokenType ||
                                '. Please report this issue here https://github.com/s-oravec/plsql-semver/issues');
    end;

    ----------------------------------------------------------------------------
    procedure raiseUnexpectedToken is
    begin
        raise_application_error(-20000, 'Unexpected token ' || currentTokenType || ':' || currentTokenText);
    end;

    ----------------------------------------------------------------------------
    procedure raiseExpectedSymbolNotFound(a_expected_symbol ast_symbol_type) is
    begin
        d.log('Expected symbol ' || a_expected_symbol || ' not found at position: ' || semver_token_stream.currentToken().sourceIndex);
        raise_application_error(-20000,
                                'Expected symbol ' || a_expected_symbol || ' not found at position: ' || semver_token_stream.currentToken()
                                .sourceIndex);
    end;

    ----------------------------------------------------------------------------
    procedure raiseUnexpectedTokenIfEOF is
    begin
        if semver_token_stream.eof then
            raiseUnexpectedToken;
        end if;
    end;

    ----------------------------------------------------------------------------
    procedure takeAny
    (
        tokenType1 in semver_lexer.token_type,
        tokenType2 in semver_lexer.token_type
    ) is
    begin
        if currentTokenType in (tokenType1, tokenType2) then
            semver_token_stream.consume;
        else
            raiseUnexpectedToken;
        end if;
    end;

    ----------------------------------------------------------------------------
    function peekTokenType(lookahead in pls_integer default 0) return semver_lexer.token_type is
    begin
        return semver_token_stream.peek(lookahead).tokenType;
    end;

    ----------------------------------------------------------------------------
    function peekTokenText(lookahead in pls_integer default 0) return semver_lexer.token_type is
    begin
        return semver_token_stream.peek(lookahead).text;
    end;

    /*
    range-set  ::= range ( logical-or range ) *
    logical-or ::= ( ' ' ) * '||' ( ' ' ) *
    range      ::= hyphen | simple ( ' ' simple ) * | ''
    hyphen     ::= partial ' - ' partial
    simple     ::= primitive | partial | tilde | caret
    primitive  ::= ( '<' | '>' | '>=' | '<=' | '=' | ) partial
    partial    ::= xr ( '.' xr ( '.' xr qualifier ? )? )?
    xr         ::= 'x' | 'X' | '*' | nr
    nr         ::= '0' | ['1'-'9'] ( ['0'-'9'] ) *
    tilde      ::= '~' partial
    caret      ::= '^' partial
    qualifier  ::= ( '-' pre )? ( '+' build )?
    pre        ::= parts
    build      ::= parts
    parts      ::= part ( '.' part ) *
    part       ::= nr | [-0-9A-Za-z]+
    */

    ----------------------------------------------------------------------------  
    procedure eatSpaces is
        l_consumed boolean := false;
    begin
        while currentTokenType = semver_lexer.tk_Space loop
            l_consumed := true;
            semver_token_stream.consume;
        end loop;
        if l_consumed then
            d.log('spaces eaten');
        end if;
    end;

    ----------------------------------------------------------------------------  
    function take_tags return semver_ast_tags is
        l_tags semver_tags := new semver_tags();
    
        procedure takeTag is
        begin
            -- todo: add takeAny to semver_token_stream
            if currentTokenType in (semver_lexer.tk_Numeric, semver_lexer.tk_Ascii) then
                l_tags.extend();
                l_tags(l_tags.count) := currentTokenText;
                d.log('got tag: ' || currentTokenText);
                semver_token_stream.consume;
            else
                d.log('unexpected token: ' || currentTokenInfo);
                raiseUnexpectedToken;
            end if;
        end;
    
    begin
        d.log('take tags');
        semver_token_stream.takeSnapshot;
        -- parts      ::= part ( '.' part ) *
        -- part ::= nr | [-0-9A-Za-z]+    
        -- 1. take first part = tag
        takeTag;
        -- 2. take other if currentTokenType is tk_Dot  
        while currentTokenType = semver_lexer.tk_Dot loop
            semver_token_stream.consume;
            takeTag;
        end loop;
        --
        semver_token_stream.commitSnapshot;
        return semver_ast_tags.createNew(l_tags);
        --
    exception
        when others then
            d.log('exception> ' || sqlerrm);
            raise;
    end;

    ----------------------------------------------------------------------------  
    function match_partial return semver_ast_partial is
        l_major varchar2(255) := '*';
        l_minor varchar2(255) := '*';
        l_patch varchar2(255) := '*';
    
        l_prerelease semver_ast_tags;
        l_build      semver_ast_tags;
        l_result     semver_ast_partial;
    
        function take_xr return varchar2 is
            l_result varchar2(255);
        begin
            if currentTokenType = semver_lexer.tk_Numeric then
                l_result := currentTokenText;
            elsif currentTokenText in ('x', 'X', '*') then
                l_result := '*';
            else
                raiseUnexpectedToken;
            end if;
            semver_token_stream.consume;
            return l_result;
        end;
    
    begin
        -- partial    ::= xr ( '.' xr ( '.' xr qualifier ? )? )?
        -- xr         ::= 'x' | 'X' | '*' | nr
        -- nr         ::= '0' | ['1'-'9'] ( ['0'-'9'] ) *
        -- qualifier  ::= ( '-' pre )? ( '+' build )?
        -- pre        ::= parts
        -- build      ::= parts
        semver_token_stream.takeSnapshot;
        d.log('matching partial');
        -- 1. take xr > major and normalize x to *
        l_major := take_xr;
        -- 2. if currentTokenType = tk_Dot > take dot and minor
        if currentTokenType = semver_lexer.tk_dot then
            semver_token_stream.consume;
            l_minor := take_xr;
        end if;
        -- 3. if currentTokenType = tk_Dot > take dot and patch
        if currentTokenType = semver_lexer.tk_dot then
            semver_token_stream.consume;
            l_patch := take_xr;
        end if;
        -- 4. if currentTokenType = tk_Hyphen > take prerelease
        if currentTokenType = semver_lexer.tk_hyphen then
            semver_token_stream.consume;
            l_prerelease := take_tags;
        end if;
        -- 5. if currentTokenType = tk_Plus > take build
        if currentTokenType = semver_lexer.tk_plus then
            semver_token_stream.consume;
            l_build := take_tags;
        end if;
        --
        l_result := semver_ast_partial.createNew(l_major, l_minor, l_patch, l_prerelease, l_build);
        d.log('matched simple: ' || l_result.toString());
        semver_token_stream.commitSnapshot;
        --        
        return l_result;
        --
    exception
        when others then
            semver_token_stream.rollbackSnapshot;
            return null;
    end;

    ----------------------------------------------------------------------------  
    function match_simple return semver_ast_comparator is
        -- todo: type
        l_operator        varchar2(2);
        l_comparator_type varchar2(30);
    begin
        -- simple ::= primitive | partial | tilde | caret
        -- tilde  ::= '~' partial
        -- caret  ::= '^' partial
        -- primitive  ::= ( '<' | '>' | '>=' | '<=' | '=' | ) partial
        d.log('matching simple');
        -- 1. match operator
        -- 1.1. if currentTokenType in (tilde, caret, lt, gt, lte, gte, eq)
        d.log('matching operator');
        if currentTokenType in (semver_lexer.tk_tilde,
                                semver_lexer.tk_caret,
                                semver_lexer.tk_lt,
                                semver_lexer.tk_gt,
                                semver_lexer.tk_lte,
                                semver_lexer.tk_gte,
                                semver_lexer.tk_eq) then
            -- 1.1.1. set operator = currentTokenText
            l_operator := currentTokenText;
            -- 1.1.2. set comparator type based on currentTokenType
            case currentTokenType
                when semver_lexer.tk_caret then
                    l_comparator_type := COMPARATOR_TYPE_CARET;
                when semver_lexer.tk_tilde then
                    l_comparator_type := COMPARATOR_TYPE_TILDE;
                else
                    l_comparator_type := COMPARATOR_TYPE_PRIMITIVE;
            end case;
            -- 1.1.3. consume
            semver_token_stream.consume;
        else
            -- 1.2. else "silent eq"
            -- 1.2.1. set operator = '='
            l_operator := '';
            -- 1.2.2. set comparator type COMPARATOR_TYPE_PRIMITIVE
            l_comparator_type := COMPARATOR_TYPE_PRIMITIVE;
        end if;
        -- 2. match partial
        d.log('match partial');
        return semver_ast_comparator.createNew(l_comparator_type, l_operator, match_partial);
    end;

    ----------------------------------------------------------------------------  
    function match_ComparatorSet return semver_ast_ComparatorSet is
        l_comparators semver_AstChildren;
    begin
        d.log('matching ComparatorSet');
        -- range ::= hyphen | simple ( ' ' simple ) * | ''
        -- 2. hyphen?
        -- hyphen ::= partial ' - ' partial
        -- 1. snapshot - is done in match_partial
        semver_token_stream.takeSnapshot;
        l_comparators := semver_AstChildren();
        -- 2.1. match partial
        -- TODO: rewrite this
        d.log('try match hyphen');
        if appendToList(match_partial, l_comparators) then
            begin
                -- 2.2. if current token != space 
                if currentTokenType = semver_lexer.tk_Space then
                    -- 2.3. else 
                    -- 2.3.1. match space
                    semver_token_stream.take(semver_lexer.tk_Space);
                    -- 2.3.2. match hyphen
                    semver_token_stream.take(semver_lexer.tk_hyphen);
                    -- 2.3.3. match space
                    semver_token_stream.take(semver_lexer.tk_Space);
                    -- 2.3.4. match partial
                    if appendToList(match_partial, l_comparators) then
                        -- 2.3.5 return hyphen range
                        d.log('matched hyphen range');
                        return semver_ast_ComparatorSet.createNew(RANGE_TYPE_HYPHEN, l_comparators);
                    else
                        semver_token_stream.rollbackSnapshot;
                    end if;
                else
                    semver_token_stream.rollbackSnapshot;
                end if;
            exception
                when others then
                    semver_token_stream.rollbackSnapshot;
            end;
        else
            semver_token_stream.rollbackSnapshot;
        end if;
        -- 3. match simple list
        d.log('try match simple list');
        -- simple ( ' ' simple ) *
        begin
            semver_token_stream.takeSnapshot;
            l_comparators := semver_AstChildren();
            -- 3.1. match simple
            if not appendToList(match_simple, l_comparators) then
                semver_token_stream.rollbackSnapshot;
                raiseExpectedSymbolNotFound(ast_Simple);
            end if;
            -- 3.2. match list of simple comparators separated by space
            d.log('try match list of simple comparators separated by space');
            <<matchListOfSimpleComparators>>
            while currentTokenType = semver_lexer.tk_Space loop
                semver_token_stream.takeSnapshot;
                begin
                    semver_token_stream.take(semver_lexer.tk_Space);
                    if not appendToList(match_simple, l_comparators) then
                        semver_token_stream.rollbackSnapshot;
                        raiseExpectedSymbolNotFound(ast_Simple);
                    end if;
                exception
                    when others then
                        semver_token_stream.rollbackSnapshot;
                        exit matchListOfSimpleComparators;
                end;
            end loop matchListOfSimpleComparators;
            -- 3.3. return simple-list comparator
            return semver_ast_ComparatorSet.createNew(RANGE_TYPE_SIMPLE_LIST, l_comparators);
        exception
            when others then
                semver_token_stream.rollbackSnapshot;
        end;
        -- not match > create empty range if next is EOF, WhiteSpace or |
        if currentTokenType in (semver_lexer.tk_EOF, semver_lexer.tk_WhiteSpace, semver_lexer.tk_Pipe) then
            d.log('create ANY range');
            declare
                l_any_comparator semver_ast_comparator;
            begin
                l_any_comparator := semver_ast_comparator.createNew(semver_range_parser.COMPARATOR_TYPE_PRIMITIVE,
                                                                    '=',
                                                                    semver_ast_partial('*', null, null));
                return semver_ast_ComparatorSet.createNew(semver_range_parser.RANGE_TYPE_SIMPLE_LIST,
                                                          semver_astchildren(l_any_comparator.id_registry));
            end;
        end if;
    end;

    ----------------------------------------------------------------------------  
    function match_range return semver_ast_range is
        l_ranges semver_AstChildren := semver_AstChildren();
    begin
        --
        d.log('matching range');
        -- range-set ::= range ( logical-or range ) *        
        -- range
        semver_token_stream.takeSnapshot;
        d.log('try match comparator set');
        if not appendToList(match_ComparatorSet, l_ranges) then
            semver_token_stream.rollbackSnapshot;
            raiseExpectedSymbolNotFound(ast_Range);
        end if;
        -- ( logical-or range ) *
        -- ( ' ' ) * '||' ( ' ' ) *
        d.log('eating spaces');
        eatSpaces;
        while currentTokenType != semver_lexer.tk_EOF loop
            d.log('matching || operator');
            semver_token_stream.take(semver_lexer.tk_Pipe);
            semver_token_stream.take(semver_lexer.tk_Pipe);
            eatSpaces;
            d.log('matching another');
            semver_token_stream.takeSnapshot;
            if not appendToList(match_ComparatorSet, l_ranges) then
                semver_token_stream.rollbackSnapshot;
                raiseExpectedSymbolNotFound(ast_Range);
            end if;
        
        end loop;
        --
        if currentTokenType != semver_lexer.tk_EOF then
            d.log('Unexpected token');
            raiseUnexpectedToken;
        else
            return semver_ast_range.createNew(l_ranges);
        end if;
        --
    end;

    -------------------------------------------
    function parse return semver_ast_range is
    begin
        d.log('begin parsing');
        return match_range;
    end;

end;
/
