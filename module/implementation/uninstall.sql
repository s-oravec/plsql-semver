rem Common
prompt .. Dropping type SEMVER_INTEGER_TAB
drop type semver_integer_tab force;

prompt .. Dropping type SEMVER_INTEGER_STACK
drop type semver_integer_stack force;


rem Lexer
prompt .. Dropping type SEMVER_TOKEN
drop type semver_token force;

prompt .. Dropping type SEMVER_TOKENS
drop type semver_tokens force;

prompt .. Dropping type SEMVER_MATCHER
drop type semver_matcher force;

prompt .. Dropping type SEMVER_MATCHERS
drop type semver_matchers force;

prompt .. Dropping type SEMVER_MATCHASCII
drop type semver_matchascii force;

prompt .. Dropping type SEMVER_MATCHKEYWORD
drop type semver_matchkeyword force;

prompt .. Dropping type SEMVER_MATCHNUMERIC
drop type semver_matchnumeric force;


prompt .. Dropping package SEMVER_LEXER
drop package semver_lexer;


rem Parser
prompt .. Dropping type SEMVER_ASTCHILDREN
drop type semver_astchildren force;

prompt .. Dropping type SEMVER_AST
drop type semver_ast force;

prompt .. Dropping type SEMVER_AST_TAGS
drop type semver_ast_tags force;

prompt .. Dropping type SEMVER_AST_PARTIAL
drop type semver_ast_partial force;

prompt .. Dropping type SEMVER_AST_COMPARATOR
drop type semver_ast_comparator force;

prompt .. Dropping type SEMVER_AST_RANGE
drop type semver_ast_range force;

prompt .. Dropping type SEMVER_AST_RANGESET
drop type semver_ast_rangeset force;


prompt .. Dropping package SEMVER_TOKEN_STREAM
drop package semver_token_stream;

prompt .. Dropping package SEMVER_AST_REGISTRY
drop package semver_ast_registry;

prompt .. Dropping package SEMVER_RANGE_PARSER
drop package semver_range_parser;


rem Semver
prompt .. Dropping package SEMVER_COMMON
drop package semver_common;

prompt .. Dropping package SEMVER_UTIL
drop package semver_util;

prompt .. Dropping package SEMVER_VERSION_IMPL
drop package semver_version_impl;

prompt .. Dropping package SEMVER_RANGE_IMPL
drop package semver_range_impl;

prompt .. Dropping package SEMVER_COMPARATOR_IMPL
drop package semver_comparator_impl;

