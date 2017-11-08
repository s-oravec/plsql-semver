create or replace package semver_common as

    MAX_LENGTH constant pls_integer := 256;

    subtype typ_regexp_expression is varchar2(4000);
    subtype typ_regexp_modifier is varchar2(30);
    type typ_regexp is record(
        expression typ_regexp_expression,
        modifier   typ_regexp_modifier);
    subtype typ_regexp_name is varchar2(30);
    type typ_regexp_tab is table of typ_regexp index by varchar2(30);

    function regexpRecord
    (
        a_expression in typ_regexp_expression,
        a_modifier   in typ_regexp_modifier default null
    ) return typ_regexp;

end;
/
