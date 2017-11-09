create or replace type semver_range_set as object (
      text  varchar2(255),
      items semver_ranges
    );
/