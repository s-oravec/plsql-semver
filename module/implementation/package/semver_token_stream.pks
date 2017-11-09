create or replace package semver_token_stream as

    procedure initialize(a_value in varchar2);

    function getIndex return pls_integer;

    function currentToken return plex_token;

    procedure consume;

    function eof return boolean;

    function peek(p_lookahead pls_integer) return plex_token;

    procedure takeSnapshot;

    procedure rollbackSnapshot;

    procedure commitSnapshot;

    function capture(ast semver_ast) return semver_ast;

    function take return plex_token;
    function take(tokenType plex.token_type) return plex_token;
    procedure take(tokenType plex.token_type);

    function takeReservedWord(Text varchar2) return plex_token;
    procedure takeReservedWord(Text varchar2);

    function alt(ast semver_ast) return boolean;

end;
/
