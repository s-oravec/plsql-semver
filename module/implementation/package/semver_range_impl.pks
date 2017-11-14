create or replace package semver_range_impl as

    function parse(a_value in varchar2) return semver_range_set;

end;
/
