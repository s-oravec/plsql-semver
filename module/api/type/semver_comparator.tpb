create or replace type body semver_comparator as

    ----------------------------------------------------------------------------  
    member function to_string return varchar2 is
    begin
        if self.version is not null then
            return self.operator || self.version.to_string();
        else
            return self.operator;
        end if;
    end;

end;
/
