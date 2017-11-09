create or replace type body semver_token as

    ----------------------------------------------------------------------------
    constructor function semver_token(tokenType in varchar2) return self as result is
    begin
        self.tokenType := tokenType;
        self.text      := null;
        -- position of token    
        self.sourceIndex := semver_lexer.getIndex;
        --
        return;
    end;

    ----------------------------------------------------------------------------
    constructor function semver_token
    (
        tokenType in varchar2,
        Text      in varchar2
    ) return self as result is
    begin
        self.tokenType := tokenType;
        self.text      := Text;
        -- position of token    
        self.sourceIndex := semver_lexer.getIndex;
        --
        return;
    end;

    ----------------------------------------------------------------------------
    member function matchText
    (
        Text       in varchar,
        ignoreCase boolean default true
    ) return boolean is
    begin
        if ignoreCase then
            return upper(text) = upper(self.text);
        else
            return text = self.text;
        end if;
    end;

end;
/
