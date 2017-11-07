create or replace package semver_util as

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

end;
/
