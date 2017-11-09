create or replace package semver_lexer as

    subtype token_type is varchar2(30);

    -- symbols
    tk_hyphen  constant token_type := '-';
    tk_plus    constant token_type := '=';
    tk_lte     constant token_type := '<=';
    tk_gte     constant token_type := '>=';
    tk_lt      constant token_type := '<';
    tk_gt      constant token_type := '>';
    tk_eq      constant token_type := '=';
    tk_caret   constant token_type := '^';
    tk_tilde   constant token_type := '~';
    tk_asterix constant token_type := '*';
    tk_dot     constant token_type := '.';
    tk_pipe    constant token_type := '|';
    tk_space   constant token_type := ' ';

    -- tokenss
    tk_WhiteSpace constant token_type := '<WhiteSpace>';
    tk_EOF        constant token_type := '<EOF>';
    tk_Numeric    constant token_type := '<numeric>';
    tk_ASCII      constant token_type := '<ascii>';

    ----------------------------------------------------------------------------
    -- Exposed LexemeTokenizer methods
    ----------------------------------------------------------------------------
    function getIndex return pls_integer;

    procedure initialize(a_value in varchar2);

    function currentItem return varchar2;

    procedure consume;

    function eof return boolean;

    function peek(p_lookahead pls_integer) return varchar2;

    procedure takeSnapshot;

    procedure rollbackSnapshot;

    procedure commitSnapshot;

    function isSpecialCharacter(p_character in varchar2) return boolean;

    ----------------------------------------------------------------------------
    -- Lexer methods
    ----------------------------------------------------------------------------
    function nextToken return semver_token;

    function tokens return semver_tokens;

end;
/
