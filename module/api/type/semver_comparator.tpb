create or replace type body semver_comparator as

    ----------------------------------------------------------------------------  
    member function to_string return varchar2 is
    begin
        if self.version is not null then
            return self.operator || self.version.to_string();
        else
            -- semver.ANY = semver_comparator(null, null)
            -- TODO: fix this somehow
            -- return '*';
            return '';
        end if;
    end;

    ----------------------------------------------------------------------------
    member function test(version in semver_version) return boolean is
    begin
        return semver_comparator_impl.test(self, version);
    end;

    ----------------------------------------------------------------------------
    member function intersects(comparator in semver_comparator) return boolean is
    begin
        return semver_comparator_impl.intersects(self, comparator);
    end;

end;
/
