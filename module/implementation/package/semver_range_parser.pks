create or replace package semver_range_parser as

    /**
    AST Symbol Type
    */
    subtype ast_symbol_type is varchar2(30);

    -- AST Symbols
    ast_RangeSet   constant ast_symbol_type := 'RangeSet';
    ast_Range      constant ast_symbol_type := 'Range';
    ast_Comparator constant ast_symbol_type := 'Comparator';
    ast_Partial    constant ast_symbol_type := 'Partial';
    ast_Simple     constant ast_symbol_type := 'Simple';
    ast_Tags       constant ast_symbol_type := 'Tags';

    RANGE_TYPE_HYPHEN      constant varchar2(30) := 'hyphen';
    RANGE_TYPE_SIMPLE_LIST constant varchar2(30) := 'simple-list';

    COMPARATOR_TYPE_TILDE     constant varchar2(30) := 'tilde';
    COMPARATOR_TYPE_CARET     constant varchar2(30) := 'caret';
    COMPARATOR_TYPE_PRIMITIVE constant varchar2(30) := 'primitive';

    -- initializes parser with source
    procedure initialize(a_value in varchar2);

    -- parse source lines and return root AST
    function parse return semver_ast;

end;
/
