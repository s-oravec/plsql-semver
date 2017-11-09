create or replace package body semver_common as

    g_src typ_regexp_tab;

    ----------------------------------------------------------------------------
    function regexpRecord
    (
        a_expression in typ_regexp_expression,
        a_modifier   in typ_regexp_modifier default null
    ) return typ_regexp is
        l_result typ_regexp;
    begin
        l_result.expression := a_expression;
        l_result.modifier   := a_modifier;
        return l_result;
    end;

    ----------------------------------------------------------------------------
    function src(a_regexp_name in typ_regexp_name) return typ_regexp is
    begin
        return g_src(a_regexp_name);
    end;

begin

    g_src(IS_NUMERIC) := regexpRecord('^[0-9]+$');
    g_src(DELIMITERS) := regexpRecord('(\.)|(\+)|-');
    g_src(NUMERICIDENTIFIER) := regexpRecord('0|[1-9]\d*');
    g_src(NONNUMERICIDENTIFIER) := regexpRecord('\d*[a-zA-Z-][a-zA-Z0-9-]*');
    g_src(BUILDIDENTIFIER) := regexpRecord('[0-9a-zA-Z-]+');
    -- NoFormat Start
    g_src(MAINVERSION) := regexpRecord('(' || g_src(NUMERICIDENTIFIER).expression || ')\.' ||
                                     '(' || g_src(NUMERICIDENTIFIER).expression || ')\.' ||
                                     '(' || g_src(NUMERICIDENTIFIER).expression || ')');
    g_src(PRERELEASEIDENTIFIER) := regexpRecord('(' || g_src(NUMERICIDENTIFIER).expression ||
                                              '|' || g_src(NONNUMERICIDENTIFIER).expression || ')');
    g_src(PRERELEASE) := regexpRecord('(-(' || g_src(PRERELEASEIDENTIFIER).expression ||
                                    '(\.' || g_src(PRERELEASEIDENTIFIER).expression || ')*))');
    g_src(BUILD) := regexpRecord('(\+(' || g_src(BUILDIDENTIFIER).expression ||
                               '(\.' || g_src(BUILDIDENTIFIER).expression || ')*))');
    --
    -- oracle's regexp implementation just sucks
    --g_src(FULLVERSION) := regexpRecord('^' || 'v?' || g_src(MAINVERSION).expression || g_src(PRERELEASE).expression || '?' || g_src(BUILD).expression || '?' || '$');
    -- simplified
    g_src(FULLVERSION) := regexpRecord('^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-[a-zA-Z0-9\.-]*)?(\+[a-zA-Z0-9\.-]*)?$');
    g_src(GTLT) := regexpRecord('((<|>)?=?)');

    g_src(XRANGEIDENTIFIER) := regexpRecord(src(NUMERICIDENTIFIER).expression || '|x|X|\*');

    --src[XRANGEPLAIN] = '[v=\\s]*(' + src[XRANGEIDENTIFIER] + ')' +
    --                   '(?:\\.(' + src[XRANGEIDENTIFIER] + ')' +
    --                   '(?:\\.(' + src[XRANGEIDENTIFIER] + ')' +
    --                   '(?:' + src[PRERELEASE] + ')?' +
    --                   src[BUILD] + '?' +
    --                   ')?)?';
    g_src(XRANGEPLAIN) := regexpRecord('[v=\s]*(' || src(XRANGEIDENTIFIER).expression || ')' ||
                       '(\.(' || src(XRANGEIDENTIFIER).expression || ')' ||
                       '(\.(' || src(XRANGEIDENTIFIER).expression || ')' ||
                       '(' || src(PRERELEASE).expression || ')?' ||
                       src(BUILD).expression || '?' ||
                       ')?)?');
    --src[XRANGE] = '^' + src[GTLT] + '\\s*' + src[XRANGEPLAIN] + '$';
    g_src(XRANGE) := regexpRecord('^' || src(GTLT).expression || '\s*' || src(XRANGEPLAIN).expression || '$');
    g_src(LONETILDE) := regexpRecord('(~>?)');
    --src[TILDETRIM] = '(\\s*)' + src[LONETILDE] + '\\s+';
    g_src(TILDETRIM) := regexpRecord('(\s*)' || src(LONETILDE).expression || '\s+');
    --src[TILDE] = '^' + src[LONETILDE] + src[XRANGEPLAIN] + '$';
    g_src(TILDE) := regexpRecord('^' || src(LONETILDE).expression || src(XRANGEPLAIN).expression || '$');
    --src[LONECARET] = '(?:\\^)';
    g_src(LONECARET) := regexpRecord('(\^)');
    --src[CARETTRIM] = '(\\s*)' + src[LONECARET] + '\\s+';
    g_src(CARETTRIM) := regexpRecord('(\s*)' || src(LONECARET).expression || '\s+');
    --src[CARET] = '^' + src[LONECARET] + src[XRANGEPLAIN] + '$';
    g_src(CARET) := regexpRecord('^' || src(LONECARET).expression || src(XRANGEPLAIN).expression || '$');
    --src[COMPARATOR] = '^' + src[GTLT] + '\\s*(' + FULLPLAIN + ')$|^$';
    g_src(COMPARATOR) := regexpRecord('^' || src(GTLT).expression || '\s*(' || src(FULLVERSION).expression || ')$|^$');
    --
    -- TODO:
    -- An expression to strip any whitespace between the gtlt and the thing
    -- it modifies, so that `> 1.2.3` ==> `>1.2.3`
    --
    --src[HYPHENRANGE] = '^\\s*(' + src[XRANGEPLAIN] + ')' +
    --                   '\\s+-\\s+' +
    --                   '(' + src[XRANGEPLAIN] + ')' +
    --                   '\\s*$';
    g_src(HYPHENRANGE) := regexpRecord('^\s*(' || src(XRANGEPLAIN).expression || ')' ||
                       '\s+-\s+' ||
                       '(' || src(XRANGEPLAIN).expression || ')' ||
                       '\s*$');
    --src[STAR] = '(<|>)?=?\\s*\\*';
    g_src(STAR) := regexpRecord('(<|>)?=?\s*\*');
    -- NoFormat End

end;
/
