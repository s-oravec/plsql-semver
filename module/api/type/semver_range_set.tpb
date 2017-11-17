create or replace type body semver_range_set as

    ----------------------------------------------------------------------------  
    constructor function semver_range_set(value in varchar2) return self as result is
        l_parsed_semver_range_set semver_range_set;
    begin
        l_parsed_semver_range_set := semver_range_impl.parse(value);
        self.ranges               := l_parsed_semver_range_set.ranges;
        return;
    end;

    ----------------------------------------------------------------------------
    member function to_string return varchar2 is
        l_result varchar2(32767);
    begin
        for i in 1 .. self.ranges.count loop
            l_result := l_result || semver_util.ternary_varchar2(i = 1, self.ranges(i).to_string(), '||' || self.ranges(i).to_string());
        end loop;
        return nvl(l_result, '*');
    end;

    ----------------------------------------------------------------------------  
    member function test(version in semver_version) return boolean is
    begin
        return semver_range_impl.test(self, version);
    end;

    ----------------------------------------------------------------------------  
    member function intersects(range_set in semver_range_set) return boolean is
    begin
        return semver_range_impl.intersects(self, range_set);
    end;

end;
/
