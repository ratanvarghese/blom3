DELETE FROM grid;
DELETE FROM grid_categories;

INSERT INTO grid_categories (id, class, name)
VALUES
	(1, 'featured', 'Featured');

INSERT INTO grid (category_id, href, img_src, label)
SELECT 1, '/'||url, '/'||url||'/attachments/thumbnail.svg', title
FROM articles
INNER JOIN article_tags ON articles.id = article_tags.article_id
INNER JOIN tags ON tags.id = article_tags.tag_id
WHERE tags.name = 'featured'
ORDER BY articles.id DESC;

UPDATE grid
SET
img_src = '/chatgpt/attachments/chatgpt_big.svg',
label = NULL
WHERE href = '/chatgpt';

UPDATE grid
SET
img_src = '/z-bird/attachments/bird_head.webp',
label = NULL
WHERE href = '/z-bird';

UPDATE grid
SET
img_src = CONCAT(href, '/attachments/thumbnail.jpg'),
label = NULL
WHERE href IN (
	'/animorphs-font',
	'/predictions-for-avatar',
	'/dumbphone',
	'/creator-movie'
);