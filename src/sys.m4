divert(-1)
define(`_EDITDAY_TQ', `m4wrap(syscmd(_TQ_PATH _EDITDAY_GR))')
define(`_WRITEDAY_TQ', `m4wrap(syscmd(_TQ_PATH _WRITEDAY_GR))')
define(`_TODAY_TQ', `m4wrap(syscmd(_TQ_PATH _TODAY_GR))')
define(`_ARTICLE_CONTENT', `include(_PUBLIC_PATH/_BASICLINK)')
divert(0)dnl
