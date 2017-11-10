create or replace package semver_token_stream as

    procedure initialize(a_value in varchar2);

    function getIndex return pls_integer;

    function currentToken return semver_token;

    procedure consume;

    function eof return boolean;

    function peek(p_lookahead pls_integer) return semver_token;

    procedure takeSnapshot;

    procedure rollbackSnapshot;

    procedure commitSnapshot;

    function capture(ast semver_ast) return semver_ast;

    function take return semver_token;

    function take(tokenType semver_lexer.token_type) return semver_token;

    procedure take(tokenType semver_lexer.token_type);

    function alt(ast semver_ast) return boolean;

end;
/
