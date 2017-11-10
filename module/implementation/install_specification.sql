rem Common
prompt .. Creating type SEMVER_INTEGER_TAB
@@type/semver_integer_tab.tps;

prompt .. Creating type SEMVER_INTEGER_STACK
@@type/semver_integer_stack.tps;


rem Lexer
prompt .. Creating type SEMVER_TOKEN
@@type/semver_token.tps;

prompt .. Creating type SEMVER_TOKENS
@@type/semver_tokens.tps;

prompt .. Creating type SEMVER_MATCHER
@@type/semver_matcher.tps;

prompt .. Creating type SEMVER_MATCHERS
@@type/semver_matchers.tps;

prompt .. Creating type SEMVER_MATCHASCII
@@type/semver_matchascii.tps;

prompt .. Creating type SEMVER_MATCHKEYWORD
@@type/semver_matchkeyword.tps;

prompt .. Creating type SEMVER_MATCHNUMERIC
@@type/semver_matchnumeric.tps;


prompt .. Creating package SEMVER_LEXER
@@package/semver_lexer.pks;


rem Parser
prompt .. Creating type SEMVER_ASTCHILDREN
@@type/semver_astchildren.tps;

prompt .. Creating type SEMVER_AST
@@type/semver_ast.tps;

prompt .. Creating type SEMVER_AST_TAGS
@@type/semver_ast_tags.tps;

prompt .. Creating type SEMVER_AST_PARTIAL
@@type/semver_ast_partial.tps;

prompt .. Creating type SEMVER_AST_COMPARATOR
@@type/semver_ast_comparator.tps;

prompt .. Creating type SEMVER_AST_RANGE
@@type/semver_ast_range.tps;

prompt .. Creating type SEMVER_AST_RANGESET
@@type/semver_ast_rangeset.tps;


prompt .. Creating package SEMVER_TOKEN_STREAM
@@package/semver_token_stream.pks;

prompt .. Creating package SEMVER_AST_REGISTRY
@@package/semver_ast_registry.pks;

prompt .. Creating package SEMVER_RANGE_PARSER
@@package/semver_range_parser.pks;


rem Semver
prompt .. Creating package SEMVER_COMMON
@@package/semver_common.pks;

prompt .. Creating package SEMVER_UTIL
@@package/semver_util.pks;

prompt .. Creating package SEMVER_VERSION_IMPL
@@package/semver_version_impl.pks;

prompt .. Creating package SEMVER_RANGE_IMPL
@@package/semver_range_impl.pks;

