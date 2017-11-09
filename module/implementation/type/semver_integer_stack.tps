create or replace type semver_integer_stack as object
(

    stack_items semver_integer_tab,

    constructor function semver_integer_stack return self as result,
    member procedure push
    (
        self   in out semver_integer_stack,
        p_item integer
    ),
    member function pop(self in out semver_integer_stack) return integer,
    member procedure pop(self in out semver_integer_stack),
-- 1 true, 0 false
    member function isEmtpy(self in out semver_integer_stack) return integer

)
/
