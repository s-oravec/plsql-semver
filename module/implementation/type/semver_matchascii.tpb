create or replace type body semver_matchASCII as

    ----------------------------------------------------------------------------  
    constructor function semver_matchASCII return self as result is
    begin
        return;
    end;

    ----------------------------------------------------------------------------  
    overriding member function isMatchImpl return semver_token is
        l_Text varchar2(4000);
        procedure consumeAndAppend is
        begin
            l_Text := l_Text || semver_lexer.currentItem;
            semver_lexer.consume;
        end;
    begin
        -- \d*[a-zA-Z][a-zA-Z0-9-] *
        -- \d*
        while not semver_lexer.eof and ascii(semver_lexer.currentItem) between ascii('0') and ascii('9') loop
            consumeAndAppend;
        end loop;
        --[a-zA-Z] - has to contain ASCII
        if not regexp_like(semver_lexer.currentItem, '[a-zA-Z]') then
            return null;
        end if;
        -- consume all [a-zA-Z0-9-]
        while not semver_lexer.eof and regexp_like(semver_lexer.currentItem, '[a-ZA-Z0-9-]') loop
            consumeAndAppend;
        end loop;
        --
        if length(l_Text) > 0 then
            return new semver_token(semver_lexer.tk_ASCII, l_Text);
        else
            return null;
        end if;
    end;

end;
/
