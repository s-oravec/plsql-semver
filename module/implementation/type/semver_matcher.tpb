create or replace type body semver_matcher as

    ----------------------------------------------------------------------------  
    member function isMatch return semver_token is
        l_matchedToken semver_token;
    begin
        if semver_lexer.eof then
            return new semver_token(semver_lexer.tk_EOF);
        end if;
        semver_lexer.takeSnapshot;
        l_matchedToken := isMatchImpl();
        if l_matchedToken is null then
            semver_lexer.rollbackSnapshot;
        else
            semver_lexer.commitSnapshot;
        end if;
        return l_matchedToken;
    end;

    ----------------------------------------------------------------------------
    member function isMatchImpl return semver_token is
    begin
        raise_application_error(-20000, 'this should be overriden by matcher');
        return null;
    end;

end;
/
