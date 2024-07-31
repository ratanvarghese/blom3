.separator '\n'

SELECT
    FORMAT(
        '%s+ [%s](/%s), short URL: [r3n.me/%s](/%s)',
        CASE
            WHEN tq_months.name IS NOT NULL OR tq_intercalary.id = 1 THEN
                FORMAT('%s### %s, %d AT%s',
                    char(10),
                    CASE
                        WHEN tq_intercalary.id = 1 THEN tq_intercalary.name
                        ELSE tq_months.name
                    END,
                    STRFTIME('%Y',date_published) - 1969 + 1 - year_diff,
                    char(10)
                )
            ELSE ''
        END,
        title,
        url,
        articles.id,
        articles.id
    )
FROM articles
LEFT JOIN gr_tq_lookup AS tq_p
    ON tq_p.gr_month = STRFTIME('%m', date_published)
    AND tq_p.gr_day_of_month = STRFTIME('%d', date_published)
LEFT JOIN tq_months
    ON tq_p.tq_month = tq_months.id
    AND articles.id IN (
        SELECT MAX(id)
        FROM articles
        LEFT JOIN gr_tq_lookup AS tq_p
            ON tq_p.gr_month = STRFTIME('%m', date_published)
            AND tq_p.gr_day_of_month = STRFTIME('%d', date_published)
        GROUP BY STRFTIME('%Y',date_published) - 1969 + 1 - year_diff, tq_month
    )
LEFT JOIN tq_intercalary
    ON tq_p.tq_month IS NULL
    AND tq_p.tq_day_of_month = tq_intercalary.id
ORDER BY articles.id DESC;