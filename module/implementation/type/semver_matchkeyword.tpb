create or replace type body semver_matchkeyword as

    ----------------------------------------------------------------------------  
    constructor function semver_matchkeyword
    (
        tokenType        in varchar2,
        stringToMatch    in varchar2,
        allowAsSubstring in varchar2 default 'Y'
    ) return self as result is
    begin
        --
        self.tokenType        := tokenType;
        self.stringToMatch    := stringToMatch;
        self.allowAsSubstring := allowAsSubstring;
        --
        return;
    end;

    ----------------------------------------------------------------------------  
    overriding member function isMatchImpl return semver_token is
        l_Text  varchar2(255);
        l_found boolean;
        l_next  varchar2(1);
    begin
        for charIdx in 1 .. length(self.stringToMatch) loop
            if upper(semver_lexer.currentItem) = upper(substr(self.stringToMatch, charIdx, 1)) then
                l_Text := l_Text || semver_lexer.currentItem;
                semver_lexer.consume;
            else
                return null;
            end if;
        end loop;
        if self.allowAsSubstring = 'N' then
            l_next  := semver_lexer.currentItem;
            l_found := regexp_like(l_next, '\s') or semver_lexer.isSpecialCharacter(l_next) or semver_lexer.eof;
        else
            l_found := true;
        end if;
        if l_found then
            return new semver_token(self.tokenType, l_Text);
        end if;
        return null;
    end;

end;
/
