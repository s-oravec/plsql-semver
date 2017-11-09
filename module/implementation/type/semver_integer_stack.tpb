create or replace type body semver_integer_stack as

    ---------------------------------------------------------------------------- 
    constructor function semver_integer_stack return self as result is
    begin
        self.stack_items := semver_integer_tab();
        return;
    end;

    ---------------------------------------------------------------------------- 
    member procedure push
    (
        self   in out semver_integer_stack,
        p_item integer
    ) is
    begin
        self.stack_items.extend();
        self.stack_items(self.stack_items.count) := p_item;
    end;

    ---------------------------------------------------------------------------- 
    member function pop(self in out semver_integer_stack) return integer is
        l_Result integer;
    begin
        if self.stack_items.count != 0 then
            l_Result := self.stack_items(self.stack_items.count);
            self.stack_items.trim;
        else
            raise_application_error(-20000, 'Stack is empty!');
        end if;
        return l_Result;
    end;

    ---------------------------------------------------------------------------- 
    member procedure pop(self in out semver_integer_stack) is
        l_dummy pls_integer;
    begin
        l_dummy := self.pop();
    end;

    ----------------------------------------------------------------------------
    member function isEmtpy(self in out semver_integer_stack) return integer is
    begin
        if self.stack_items.count = 0 then
            return 1;
        else
            return 0;
        end if;
    end;

end;
/
