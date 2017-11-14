create or replace package body semver_range_impl as

    d debug := new debug('semver:range');

    /*
    
    range-set  ::= range ( logical-or range ) *
    logical-or ::= ( ' ' ) * '||' ( ' ' ) *
    range      ::= hyphen | simple ( ' ' simple ) * | ''
    hyphen     ::= partial ' - ' partial
    simple     ::= primitive | partial | tilde | caret
    primitive  ::= ( '<' | '>' | '>=' | '<=' | '=' | ) partial
    partial    ::= xr ( '.' xr ( '.' xr qualifier ? )? )?
    xr         ::= 'x' | 'X' | '*' | nr
    nr         ::= '0' | ['1'-'9'] ( ['0'-'9'] ) *
    tilde      ::= '~' partial
    caret      ::= '^' partial
    qualifier  ::= ( '-' pre )? ( '+' build )?
    pre        ::= parts
    build      ::= parts
    parts      ::= part ( '.' part ) *
    part       ::= nr | [-0-9A-Za-z]+
    
    */

    ---------------------------------------------------------------------------- 
    function parse(a_value in varchar2) return semver_range_set is
        l_ast_rangeset semver_ast_rangeset;
        l_range_set    semver_range_set;
    begin
        d.log('parse: ' || a_value);
        d.log('initialize parser');
        semver_range_parser.initialize(a_value);
        begin
            d.log('parsing');
            l_ast_rangeset := semver_range_parser.parse;
            d.log('translating sevmer_ast_rangeset to semver_range_set');
            l_range_set := l_ast_rangeset.get_range_set;
            d.log('returning translated semver_range_set');
            return l_range_set;
        exception
            when others then
                raise;
        end;
    end;

end;
/
