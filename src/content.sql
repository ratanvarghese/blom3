.separator "\n"

SELECT
	writefile((SELECT @public_dir) || '/'||url||"/content.md", content_md),
	writefile((SELECT @public_dir) || '/'||url||"/item.m4",(
		FORMAT("divert(-1)
changequote(`[',`]')
define([_WRITEDAY_GR], [%s])
define([_EDITDAY_GR], [%s])
define([_TODAY_GR], [%s])
define([_PERMALINK], [/%s])
define([_MDLINK], [/%s/content.md])
define([_BASICLINK], [/%s/content.html])
define([_TITLE], [%s])
define([_ARTICLE_CLASS], [%s])
changequote
define(`_TAGS_LIST', `%s')
divert(0)dnl
",
				date(date_published),
				date(date_modified),
				date(),
				url,
				url,
				url,
				title,
				COALESCE(class, ""),
				(
					SELECT group_concat(FORMAT("_TAG_ITEM(%s)", tags.name), char(10))
					FROM tags
					INNER JOIN article_tags ON tags.id = article_tags.tag_id
					WHERE article_tags.article_id = articles.id
				)
			)
		)
	)
FROM articles;