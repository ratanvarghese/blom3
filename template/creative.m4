divert(-1)
define(`_TODAY_CMD', `date --iso-8601 | tr -d "\n"')
define(`_TODAY_GR', `m4wrap(syscmd(_TODAY_CMD))')
define(`_TODAY_TQ', `m4wrap(syscmd(_TQ_PATH $(_TODAY_CMD)))')
define(`_COMMENT_SECTION', `')
define(`_ARTICLE_CLASS', `creative')
define(`_TOTAL_CONTENT', `include(_CONTENT_PATH)')
divert
