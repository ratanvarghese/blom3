SELECT json_patch(json_object(
	'version', (SELECT @feed_version),
	'title', (SELECT @feed_title),
	'home_page_url', (SELECT @home_page_url),
	'feed_url', (SELECT @home_page_url) || '/feeds/json'
),
'{"items": [' ||
	(SELECT group_concat(item)
	FROM (
		SELECT json_object(
	        'url', (SELECT @article_url_prefix) || '/' || url,
	        'id', (SELECT @article_url_prefix) || '/' || url,
	        'title', title,
	        'date_modified', date_modified,
	        'date_published', date_published,
	        'attachments', (
	            SELECT
	                json_group_array(json_object(
	                	'file_name', FORMAT(
	                		'%s/%s/attachments/%s',
	                		(SELECT @home_page_url),
	                		url,
	                		file_name
	                	),
	                	'mime_type', mime_type
	                ))
	            FROM attachments
	            WHERE attachments.article_id = articles.id
	        ),
	        'tags', (
	            SELECT
	                json_group_array(tags.name)
	            FROM tags
	            INNER JOIN article_tags ON tags.id = article_tags.tag_id
	            WHERE article_tags.article_id = articles.id
	        ),
	        'content_html', CAST(readfile((SELECT @public_dir) || '/' || url || '/content.html') AS TEXT)
	    ) AS item
		FROM articles
		ORDER BY id DESC))
|| ']}'
);