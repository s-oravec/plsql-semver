create or replace type body semver_range as

    ----------------------------------------------------------------------------  
    member function to_string return varchar2 is
        l_result varchar2(32767);
    begin
        for i in 1 .. self.comparators.count loop
            l_result := l_result ||
                        semver_util.ternary_varchar2(i = 1, self.comparators(i).to_string(), ' ' || self.comparators(i).to_string());
        end loop;
        return l_result;
    end;

    ----------------------------------------------------------------------------
    member function test(version in semver_version) return boolean is
    begin
        return semver_range_impl.test(self, version);
    end;

end;
/
