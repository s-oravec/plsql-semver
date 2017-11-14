create or replace package body semver_lexer as

    d debug := new debug('semver:lexer');

    g_index           pls_integer;
    g_line            pls_integer;
    g_lineIndex       pls_integer;
    g_snapshotIndexes semver_integer_stack;
    g_source          varchar2(255);

    type typ_tableOfTokens is table of semver_lexer.token_type;
    g_specialCharacterTokens typ_tableOfTokens;

    g_matchers semver_matchers;

    ----------------------------------------------------------------------------
    function getIndex return pls_integer is
    begin
        return g_index;
    end;

    ----------------------------------------------------------------------------
    function getLine return pls_integer is
    begin
        return g_line;
    end;

    ----------------------------------------------------------------------------
    function getLineIndex return pls_integer is
    begin
        return g_lineIndex;
    end;

    ----------------------------------------------------------------------------
    procedure initializeMatchers is
        procedure appendMatcher(p_matcher semver_matcher) is
        begin
            g_matchers.extend();
            g_matchers(g_matchers.count) := p_matcher;
        end;
    begin
        g_matchers := semver_matchers();
        -- order of append matchers into g_metchers is significant - they are evaluated in that order
        --
        -- add special characters matchers
        for idx in 1 .. g_specialCharacterTokens.count loop
            appendMatcher(new semver_matchKeyword(g_specialCharacterTokens(idx), g_specialCharacterTokens(idx)));
        end loop;
        --
        -- add matcher for matching number literals
        appendMatcher(new semver_matchNumeric());
        --
        -- add matcher for matching string literals
        appendMatcher(new semver_matchASCII());
        --
    end;

    ----------------------------------------------------------------------------
    procedure initialize(a_value in varchar2) is
    begin
        d.log('initializing lexer with value: "' || a_value || '"');
        -- set indexes (we index from 1 in PLSQL)
        g_index := 1;
        -- init snapshot global stacks
        g_snapshotIndexes := semver_integer_stack();
        --
        g_source := a_value;
        --
        initializeMatchers;
    end;

    ----------------------------------------------------------------------------
    function eof(p_lookahead pls_integer) return boolean is
    begin
        if g_source is null or g_index + p_lookahead > length(g_source) then
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
    function peek(p_lookahead pls_integer) return varchar2 is
        l_result varchar2(1);
    begin
        if eof(p_lookahead) then
            return null;
        else
            l_result := substr(g_source, g_index + p_lookahead, 1);
            return l_result;
        end if;
    end;

    ----------------------------------------------------------------------------
    function currentItem return varchar2 is
    begin
        if (eof(0)) then
            return null;
        else
            return substr(g_source, g_index, 1);
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
    function isSpecialCharacter(p_character in varchar2) return boolean is
    begin
        return p_character in(tk_hyphen,
                              tk_plus,
                              tk_lte,
                              tk_gte,
                              tk_lt,
                              tk_gt,
                              tk_eq,
                              tk_caret,
                              tk_tilde,
                              tk_asterix,
                              tk_dot,
                              tk_pipe,
                              tk_space);
    end;

    ----------------------------------------------------------------------------
    function nextTokenImpl return semver_token is
        l_result semver_token;
    begin
        if eof then
            l_result := new semver_token(semver_lexer.tk_EOF);
        else
            for matcherIdx in 1 .. g_matchers.count loop
                l_result := g_matchers(matcherIdx).isMatch();
                exit when l_result is not null;
            end loop;
        end if;
        return l_result;
    exception
        when others then
            d.log('exception>' || sqlerrm);
    end;

    ----------------------------------------------------------------------------
    function nextToken return semver_token is
        l_result semver_token;
    begin
        l_result := nextTokenImpl();
        while l_result is not null and l_result.tokenType != semver_lexer.tk_EOF loop
            return l_result;
            l_result := nextTokenImpl;
        end loop;
        if l_result is null then
            d.log('Unknown token at ' || g_line || ':' || g_lineIndex || ' "' || substr(g_source, g_index, 10) || ' ..."');
            raise_application_error(-20000,
                                    'Unknown token at ' || g_line || ':' || g_lineIndex || ' "' || substr(g_source, g_index, 10) || ' ..."');
        else
            return l_result;
        end if;
    end;

    ----------------------------------------------------------------------------
    function tokens return semver_tokens is
        l_result semver_tokens;
    begin
        l_result := semver_tokens();
        loop
            l_result.extend;
            l_result(l_result.count) := semver_lexer.nextToken;
            d.log('token: ' || l_result(l_result.count).text);
            exit when l_result(l_result.count).tokenType = semver_lexer.tk_EOF;
        end loop;
        return l_result;
    end;

begin
    -- order is significant
    g_specialCharacterTokens := typ_tableOfTokens(tk_hyphen,
                                                  tk_plus,
                                                  tk_lte,
                                                  tk_gte,
                                                  tk_lt,
                                                  tk_gt,
                                                  tk_eq,
                                                  tk_caret,
                                                  tk_tilde,
                                                  tk_asterix,
                                                  tk_dot,
                                                  tk_pipe,
                                                  tk_space);
end semver_lexer;
/
