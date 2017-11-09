create or replace type body semver_matchNumeric as

    ----------------------------------------------------------------------------
    constructor function semver_matchNumeric return self as result is
    begin
        return;
    end;

    ----------------------------------------------------------------------------
    overriding member function isMatchImpl return semver_token is
        l_Text varchar2(255);
        procedure consumeAndAppend is
        begin
            l_Text := l_Text || semver_lexer.currentItem;
            semver_lexer.consume;
        end;
    begin
        -- '0' | ['1'-'9'] ( ['0'-'9'] ) *
        if ascii(semver_lexer.currentItem) = ascii('0') then
            consumeAndAppend;
        else
            while not semver_lexer.eof and ascii(semver_lexer.currentItem) between ascii('0') and ascii('9') loop
                consumeAndAppend;
            end loop;
        end if;
    
        if l_Text is not null then
            return new semver_token(semver_lexer.tk_Numeric, l_Text);
        end if;
    
        return null;
    end;

end;
/
