divert(-1)
define(`_TODAY_CMD', `date --iso-8601 | tr -d "\n"')
define(`_TODAY_GR', `m4wrap(syscmd(_TODAY_CMD))')
define(`_TOTAL_CONTENT', `include(_CONTENT_PATH)')
define(`_COMMENT_SECTION', `')
define(`_ARTICLE_CLASS', `')
divert(0)dnl
