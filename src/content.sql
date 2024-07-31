.separator '\n'

SELECT
	writefile((SELECT @public_dir) || '/'||url||'/content.md', content_md),
	writefile((SELECT @public_dir) || '/'||url||'/item.m4',(
		FORMAT('divert(-1)
changequote(`['',`]'')
define([_WRITEDAY_GR], [%s])
define([_EDITDAY_GR], [%s])
define([_TODAY_GR], [%s])
define([_WRITEDAY_TQ], [%s-%s])
define([_EDITDAY_TQ], [%s-%s])
define([_TODAY_TQ], [%s-%s])
define([_PERMALINK], [/%s])
define([_MDLINK], [/%s/content.md])
define([_BASICLINK], [/%s/content.html])
define([_TITLE], [%s])
define([_ARTICLE_CLASS], [%s])
changequote
define(`_TAGS_LIST'', `%s'')
divert(0)dnl
',
				date(date_published),
				date(date_modified),
				date(),
				STRFTIME('%Y', date_published) - 1969 + 1 - tq_p.year_diff,
				CASE
					WHEN tq_p.tq_month IS NULL AND tq_p.tq_day_of_month = 1 THEN 'ARM'
					WHEN tq_p.tq_month IS NULL AND tq_p.tq_day_of_month = 2 THEN 'ALD'
					WHEN tq_p.tq_month IS NULL AND tq_p.tq_day_of_month != 1 AND tq_p.tq_day_of_month != 2 THEN 'ERROR!'
					ELSE FORMAT('%s%02d', char(unicode('A') + tq_p.tq_month - 1) ,tq_p.tq_day_of_month)
				END,
				STRFTIME('%Y', date_modified) - 1969 + 1 - tq_m.year_diff,
				CASE
					WHEN tq_m.tq_month IS NULL AND tq_m.tq_day_of_month = 1 THEN 'ARM'
					WHEN tq_m.tq_month IS NULL AND tq_m.tq_day_of_month = 2 THEN 'ALD'
					WHEN tq_m.tq_month IS NULL AND tq_m.tq_day_of_month != 1 AND tq_m.tq_day_of_month != 2 THEN 'ERROR!'
					ELSE FORMAT('%s%02d', char(unicode('A') + tq_m.tq_month - 1) ,tq_m.tq_day_of_month)
				END,
				STRFTIME('%Y') - 1969 + 1 - tq_t.year_diff,
				CASE
					WHEN tq_t.tq_month IS NULL AND tq_t.tq_day_of_month = 1 THEN 'ARM'
					WHEN tq_t.tq_month IS NULL AND tq_t.tq_day_of_month = 2 THEN 'ALD'
					WHEN tq_t.tq_month IS NULL AND tq_t.tq_day_of_month != 1 AND tq_t.tq_day_of_month != 2 THEN 'ERROR!'
					ELSE FORMAT('%s%02d', char(unicode('A') + tq_t.tq_month - 1) ,tq_t.tq_day_of_month)
				END,
				url,
				url,
				url,
				title,
				COALESCE(class, ''),
				(
					SELECT group_concat(FORMAT('_TAG_ITEM(%s)', tags.name), char(10))
					FROM tags
					INNER JOIN article_tags ON tags.id = article_tags.tag_id
					WHERE article_tags.article_id = articles.id
				)
			)
		)
	)
FROM articles
INNER JOIN gr_tq_lookup AS tq_p
	ON tq_p.gr_month = STRFTIME('%m', date_published)
	AND tq_p.gr_day_of_month = STRFTIME('%d', date_published)
INNER JOIN gr_tq_lookup AS tq_m
	ON tq_m.gr_month = STRFTIME('%m', date_modified)
	AND tq_m.gr_day_of_month = STRFTIME('%d', date_modified)
INNER JOIN gr_tq_lookup AS tq_t
	ON tq_t.gr_month = STRFTIME('%m')
	AND tq_t.gr_day_of_month = STRFTIME('%d')
;