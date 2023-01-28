SELECT
	FORMAT("### [#%s](id:%s)
%s
",
		name,
		name,
		(
			SELECT group_concat(item, char(10))
			FROM (
				SELECT FORMAT("+ [%s](/%s)", articles.title, articles.url) AS item
				FROM articles
				INNER JOIN article_tags ON articles.id = article_tags.article_id
				WHERE article_tags.tag_id = tags.id
				ORDER BY articles.id DESC
			)
		)
	)
FROM tags
ORDER BY name;