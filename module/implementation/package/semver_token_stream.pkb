create or replace package body semver_token_stream as

    -- list of tokens returned
    g_tokens semver_tokens;
    -- current index
    g_index pls_integer;
    --
    g_snapshotIndexes semver_integer_stack;

    type typ_Memo is record(
        ast       semver_ast,
        nextIndex pls_integer);
    type typ_AstMemoIntDictionary is table of typ_Memo index by pls_integer;

    g_cachedAstMemo typ_AstMemoIntDictionary;

    ----------------------------------------------------------------------------
    procedure initialize_impl is
    begin
        semver_ast_registry.initialize;
        g_cachedAstMemo.delete();
        g_tokens          := semver_lexer.tokens;
        g_index           := 1;
        g_snapshotIndexes := semver_integer_stack();
    end;

    ----------------------------------------------------------------------------
    function currentToken return semver_token is
    begin
        return g_tokens(g_index);
    end;

    ----------------------------------------------------------------------------
    function isMatch(TokenType semver_lexer.token_type) return boolean is
    begin
        if currentToken().tokenType = TokenType then
            return true;
        end if;
        return false;
    end;

    ----------------------------------------------------------------------------
    procedure initialize(a_value in varchar2) is
    begin
        semver_lexer.initialize(a_value);
        initialize_impl;
    end;

    ----------------------------------------------------------------------------
    function getIndex return pls_integer is
    begin
        return g_index;
    end;

    ----------------------------------------------------------------------------
    function eof(p_lookahead pls_integer) return boolean is
    begin
        if g_tokens is null or g_index + p_lookahead > g_tokens.count or currentToken().tokenType = semver_lexer.tk_EOF then
            return true;
        else
            return false;
        end if;
    end;

    ----------------------------------------------------------------------------
    function eof return boolean is
    begin
        return eof(0);
    end;

    ----------------------------------------------------------------------------
    function peek(p_lookahead pls_integer) return semver_token is
    begin
        if eof(p_lookahead) then
            return null;
        else
            return g_tokens(g_index + p_lookahead);
        end if;
    end;

    ----------------------------------------------------------------------------
    procedure consume is
    begin
        g_index := g_index + 1;
    end;

    ----------------------------------------------------------------------------
    procedure takeSnapshot is
    begin
        g_snapshotIndexes.push(g_index);
    end;

    ----------------------------------------------------------------------------
    procedure rollbackSnapshot is
    begin
        g_index := g_snapshotIndexes.pop();
    end;

    ----------------------------------------------------------------------------
    procedure commitSnapshot is
    begin
        g_snapshotIndexes.pop();
    end;

    ----------------------------------------------------------------------------
    function getCachedOrExecute(ast semver_ast) return semver_ast is
        l_memo typ_Memo;
    begin
        if not g_cachedAstMemo.exists(g_index) then
            return ast.executeAst;
        end if;
        l_memo  := g_cachedAstMemo(g_index);
        g_index := l_memo.nextIndex;
        return l_memo.ast;
    end;

    ----------------------------------------------------------------------------
    function capture(ast semver_ast) return semver_ast is
    begin
        if alt(ast) then
            return getCachedOrExecute(ast);
        end if;
        return null;
    end;

    ----------------------------------------------------------------------------
    function take(tokenType semver_lexer.token_type) return semver_token is
        l_current semver_token;
    begin
        if isMatch(tokenType) then
            l_current := currentToken();
            consume;
            return l_current;
        end if;
        -- TODO: rewrite without exception
        raise_application_error(-20000, 'Invalid syntax. Expecting ' || tokenType || ' but got ' || currentToken().tokenType);
    end;

    ----------------------------------------------------------------------------
    procedure take(tokenType semver_lexer.token_type) is
        l_token semver_token;
    begin
        l_token := take(tokenType);
    end;

    ----------------------------------------------------------------------------
    function take return semver_token is
        l_Result semver_token;
    begin
        l_Result := currentToken();
        consume;
        return l_Result;
    end;

    ----------------------------------------------------------------------------
    function alt(ast semver_ast) return boolean is
        l_found        boolean;
        l_currentIndex pls_integer;
        l_ast          semver_ast;
        l_newMemo      typ_Memo;
    begin
        takeSnapshot;
        l_found := false;
        begin
            l_currentIndex := g_index;
            l_ast          := ast.executeAst();
            if l_ast is not null then
                l_found := true;
                l_newMemo.ast := l_ast;
                l_newMemo.nextIndex := g_index;
                g_cachedAstMemo(l_currentIndex) := l_newMemo;
            end if;
        exception
            when others then
                null;
        end;
        rollbackSnapshot;
        return l_found;
    end;

end;
/
