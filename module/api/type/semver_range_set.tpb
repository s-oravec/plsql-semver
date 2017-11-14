create or replace type body semver_range_set as

    ----------------------------------------------------------------------------  
    member function to_string return varchar2 is
        l_result varchar2(32767);
    begin
        for i in 1 .. self.ranges.count loop
            l_result := l_result || semver_util.ternary_varchar2(i = 1, self.ranges(i).to_string(), ' ' || self.ranges(i).to_string());
        end loop;
        return l_result;
    end;

end;
/
