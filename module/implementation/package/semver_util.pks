create or replace package semver_util as

    MAX_LENGTH constant pls_integer := 256;

    subtype typ_regexp_expression is varchar2(4000);
    subtype typ_regexp_modifier is varchar2(30);
    type typ_regexp is record(
        expression typ_regexp_expression,
        modifier   typ_regexp_modifier);
    subtype typ_regexp_name is varchar2(30);
    type typ_regexp_tab is table of typ_regexp index by varchar2(30);

    function value_at_position
    (
        a_delimited_string in varchar2,
        a_delimiter        in varchar2,
        a_position         in integer
    ) return varchar2;

    function join_semver_tags
    (
        a_tags      in semver_tags,
        a_delimiter in varchar2
    ) return varchar2;

    function ternary_varchar2
    (
        a_condition   in boolean,
        a_value_true  in varchar2,
        a_value_false in varchar2 default null
    ) return varchar2;

    function ternary_pls_integer
    (
        a_condition   in boolean,
        a_value_true  in pls_integer,
        a_value_false in pls_integer default null
    ) return pls_integer;

    procedure raise_exception
    (
        a_sqlcode              in pls_integer,
        a_sqlerrm_placeholder1 in varchar2
    );

end;
/
