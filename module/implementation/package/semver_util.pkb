create or replace package body semver_util as

    ----------------------------------------------------------------------------
    function value_at_position
    (
        a_delimited_string in varchar2,
        a_delimiter        in varchar2,
        a_position         in integer
    ) return varchar2 is
        l_start_position pls_integer;
        l_end_position   pls_integer;
    begin
        -- asserts
        if a_position < 1 then
            raise_application_error(-20000, 'Position value ' || a_position || ' is out of range.');
        elsif a_delimiter is null then
            raise_application_error(-20000, 'Delimiter value cannot be NULL.');
        end if;
        -- implementation
        if a_position = 1 then
            l_start_position := 1;
        else
            l_start_position := instr(a_delimited_string, a_delimiter, 1, a_position - 1) + 1;
        end if;
        l_end_position := instr(a_delimited_string, a_delimiter, 1, a_position);
        if l_start_position < 1 then
            return null;
        elsif l_end_position < 1 then
            return substr(a_delimited_string, l_start_position);
        else
            return substr(a_delimited_string, l_start_position, l_end_position - l_start_position);
        end if;
    end;

    ----------------------------------------------------------------------------
    function join_semver_tags
    (
        a_tags      in semver_tags,
        a_delimiter in varchar2
    ) return varchar2 is
        l_result varchar2(255);
    begin
        if a_tags is null or a_tags.count = 0 then
            null;
        else
            for i in 1 .. a_tags.count loop
                if i = 1 then
                    l_result := a_tags(i);
                else
                    l_result := l_result || a_delimiter || a_tags(i);
                end if;
            end loop;
        end if;
        return l_result;
    end;

    ----------------------------------------------------------------------------
    function ternary_varchar2
    (
        a_condition   in boolean,
        a_value_true  in varchar2,
        a_value_false in varchar2 default null
    ) return varchar2 is
    begin
        if a_condition then
            return a_value_true;
        else
            return a_value_false;
        end if;
    end;

end;
/