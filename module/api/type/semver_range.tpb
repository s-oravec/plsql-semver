create or replace type body semver_range as

    ----------------------------------------------------------------------------  
    constructor function semver_range(range in varchar2) return self as result is
        l_parsed_semver_range semver_range;
    begin
        l_parsed_semver_range := semver_range_impl.parse(range);
        self.comparator_sets  := l_parsed_semver_range.comparator_sets;
        return;
    end;

    ----------------------------------------------------------------------------
    member function to_string return varchar2 is
        l_result varchar2(32767);
    begin
        for i in 1 .. self.comparator_sets.count loop
            -- NoFormat Start
            l_result := l_result 
                     || semver_util.ternary_varchar2(
                            i = 1,
                            self.comparator_sets(i).to_string(),
                            '||' || self.comparator_sets(i).to_string());
            -- NoFormat End
        end loop;
        return nvl(l_result, '*');
    end;

    ----------------------------------------------------------------------------  
    member function test(version in semver_version) return boolean is
    begin
        return semver_range_impl.test(self, version);
    end;

    ----------------------------------------------------------------------------  
    member function intersects(range in semver_range) return boolean is
    begin
        return semver_range_impl.intersects(self, range);
    end;

end;
/
