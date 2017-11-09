create or replace package body semver_range_parser as

    ----------------------------------------------------------------------------
    procedure initialize(a_value in varchar2) is
    begin
        semver_token_stream.initialize(a_value);
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
    begin
        while currentTokenType = semver_lexer.tk_Space loop
            semver_token_stream.consume;
        end loop;
    end;

    ----------------------------------------------------------------------------  
    function match_tags return semver_ast_tags is
        l_tags semver_tags := new semver_tags();
    
        procedure takeTag is
        begin
            if currentTokenType in (semver_lexer.tk_Numeric, semver_lexer.tk_Ascii) then
                l_tags.extend();
                l_tags(l_tags.count) := currentTokenText;
                semver_token_stream.consume;
            else
                raiseUnexpectedToken;
            end if;
        end;
    
    begin
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
        return semver_ast_tags.createNew(l_tags);
        --
    end;

    ----------------------------------------------------------------------------  
    function match_partial return semver_ast_partial is
        l_major varchar2(255) := '*';
        l_minor varchar2(255) := '*';
        l_patch varchar2(255) := '*';
    
        l_prerelease semver_ast_tags;
        l_build      semver_ast_tags;
    
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
    
        -- 1. take xr > major & normalize x to *
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
            l_prerelease := match_tags;
        end if;
        -- 5. if currentTokenType = tk_Plus > take prerelease
        if currentTokenType = semver_lexer.tk_plus then
            semver_token_stream.consume;
            l_build := match_tags;
        end if;
        --
        return semver_ast_partial.createNew(null, l_major, l_minor, l_patch, l_prerelease, l_build);
        --
    end;

    ----------------------------------------------------------------------------  
    function match_simple return semver_ast_comparator is
        -- todo: type
        l_modifier        varchar2(2);
        l_comparator_type varchar2(30);
    begin
        -- simple ::= primitive | partial | tilde | caret
        -- tilde  ::= '~' partial
        -- caret  ::= '^' partial
        -- primitive  ::= ( '<' | '>' | '>=' | '<=' | '=' | ) partial
    
        -- 1. match modifier
        -- 1.1. if currentTokenType in (tilde, caret, lt, gt, lte, gte, eq)
        if currentTokenType in (semver_lexer.tk_tilde,
                                semver_lexer.tk_caret,
                                semver_lexer.tk_lt,
                                semver_lexer.tk_gt,
                                semver_lexer.tk_lte,
                                semver_lexer.tk_gte,
                                semver_lexer.tk_eq) then
            -- 1.1.1. set modifier = currentTokenText
            l_modifier := currentTokenText;
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
            -- 1.2.1. set modifier = '='
            l_modifier := '=';
            -- 1.2.2. set comparator type COMPARATOR_TYPE_PRIMITIVE
            l_comparator_type := COMPARATOR_TYPE_PRIMITIVE;
        end if;
        -- 2. match partial
        return semver_ast_comparator.createNew(null, l_comparator_type, l_modifier, match_partial);
    end;

    ----------------------------------------------------------------------------  
    function match_range return semver_ast_range is
        l_comparators semver_AstChildren := semver_AstChildren();
    begin
        -- range ::= hyphen | simple ( ' ' simple ) * | ''
        -- 1. snapshot
        semver_token_stream.takeSnapshot;
        -- 2. hyphen?
        -- hyphen ::= partial ' - ' partial
        -- 2.1. match partial
        if not appendToList(match_partial, l_comparators) then
            semver_token_stream.rollbackSnapshot;
            raiseExpectedSymbolNotFound(ast_Partial);
        end if;
        -- 2.2. if current token != space 
        if currentTokenType != semver_lexer.tk_Space then
            -- 2.2.1. rollback and match simple list in 3.
            semver_token_stream.rollbackSnapshot;
        else
            -- 2.3. else 
            -- 2.3.1. match space
            semver_token_stream.take(semver_lexer.tk_Space);
            -- 2.3.2. match hyphen
            semver_token_stream.take(semver_lexer.tk_hyphen);
            -- 2.3.3. match space
            semver_token_stream.take(semver_lexer.tk_Space);
            -- 2.3.4. match partial
            if not appendToList(match_partial, l_comparators) then
                semver_token_stream.rollbackSnapshot;
                raiseExpectedSymbolNotFound(ast_Partial);
            end if;
            -- 2.3.5 return hyphen range
            -- TODO: remove text from semver_ast_range
            return semver_ast_range.createNew(null, RANGE_TYPE_HYPHEN, l_comparators);
        end if;
        -- 3. match simple list
        -- simple ( ' ' simple ) *
        semver_token_stream.takeSnapshot;
        -- 3.1. match simple
        if not appendToList(match_simple, l_comparators) then
            semver_token_stream.rollbackSnapshot;
            raiseExpectedSymbolNotFound(ast_Simple);
        end if;
        -- 3.2. match list of simple comparators separated by space
        while currentTokenType = semver_lexer.tk_Space loop
            semver_token_stream.take(semver_lexer.tk_Space);
            if not appendToList(match_simple, l_comparators) then
                semver_token_stream.rollbackSnapshot;
                raiseExpectedSymbolNotFound(ast_Simple);
            end if;
        end loop;
        -- 3.3. return simple-list comparator
        return semver_ast_range.createNew(null, RANGE_TYPE_SIMPLE_LIST, l_comparators);
    end;

    ----------------------------------------------------------------------------  
    function match_range_set return semver_ast_rangeset is
        l_ranges semver_AstChildren := semver_AstChildren();
    begin
        -- range-set ::= range ( logical-or range ) *
        -- range
        semver_token_stream.takeSnapshot;
        if not appendToList(match_range, l_ranges) then
            semver_token_stream.rollbackSnapshot;
            raiseExpectedSymbolNotFound(ast_Range);
        end if;
        -- ( logical-or range ) *
        -- ( ' ' ) * '||' ( ' ' ) *
        eatSpaces;
        while currentTokenType != semver_lexer.tk_EOF loop
        
            semver_token_stream.take(semver_lexer.tk_Pipe);
            semver_token_stream.take(semver_lexer.tk_Pipe);
            eatSpaces;
        
            semver_token_stream.takeSnapshot;
            if not appendToList(match_range, l_ranges) then
                semver_token_stream.rollbackSnapshot;
                raiseExpectedSymbolNotFound(ast_Range);
            end if;
        
        end loop;
        --
        if currentTokenType != semver_lexer.tk_EOF then
            raiseUnexpectedToken;
        end if;
        --
        return semver_ast_rangeset.createNew(l_ranges);
        --
    end;

    ----------------------------------------------------------------------------
    function parse return semver_ast is
    begin
        return match_range_set;
    end;

end;
/
