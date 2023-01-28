divert(-1)
define(`_TAG_ITEM', `<li><a href="/tags/#$1">#$1</a></li>')
define(`_TOTAL_CONTENT', `<h2><a href="_PERMALINK">_TITLE</a></h2>
<p><small>
Written _WRITEDAY_TQ [_WRITEDAY_GR],
Edited _EDITDAY_TQ [_EDITDAY_GR]
</small></p>

_ARTICLE_CONTENT

<nav>
<ul>
<li><a href="_MDLINK">Markdown</a></li>
<li><a href="_BASICLINK">Basic HTML</a></li>
</ul>
<ul>
_TAGS_LIST
</ul>
</nav>')
divert(0)dnl
