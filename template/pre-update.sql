DELETE FROM grid;
DELETE FROM grid_categories;

INSERT INTO grid_categories (id, class, name)
VALUES
	(1, 'creative-visual', 'Visual'),
	(2, 'creative-prose', 'Prose');

INSERT INTO grid (category_id, href, img_src)
VALUES
	(1, '/z-bird', '/z-bird/attachments/bird_head.webp'),
	(1, '/z-bird/#Kaleidoscope', '/z-bird/attachments/kaleidoscope_center.webp');

INSERT INTO grid (category_id, href, img_src, label)
SELECT 2, '/'||url, '/'||url||'/attachments/thumbnail.svg', title
FROM articles
INNER JOIN article_tags ON articles.id = article_tags.article_id
INNER JOIN tags ON tags.id = article_tags.tag_id
WHERE tags.name = 'joy-of-writing'
ORDER BY articles.id DESC;
