SELECT '[';
SELECT
    json_object(
        'url', url,
        'title', title,
        'date_published', date_published
    ) || CASE WHEN id = 1 THEN '' ELSE ',' END
FROM articles
ORDER BY id DESC;
SELECT ']';