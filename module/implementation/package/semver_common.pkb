create or replace package body semver_common as

    ----------------------------------------------------------------------------
    function regexpRecord
    (
        a_expression in typ_regexp_expression,
        a_modifier   in typ_regexp_modifier default null
    ) return typ_regexp is
        l_result typ_regexp;
    begin
        l_result.expression := a_expression;
        l_result.modifier   := a_modifier;
        return l_result;
    end;

end;
/
