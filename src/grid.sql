SELECT 'changequote(`['',`]'')';

SELECT
	FORMAT('_GRID_COLUMN_START
_GRID_NAME([%s])
_GRID_START
%s
_GRID_END
_GRID_COLUMN_END',
		name,
		(
			SELECT group_concat(
				CASE WHEN label IS NOT NULL
					THEN FORMAT(
						'_GRID_BOX([%s], [%s], [%s], [%s])',
						class,
						href,
						img_src,
						label
					)
					ELSE FORMAT(
						'_GRID_BOX([%s], [%s], [%s])',
						class,
						href,
						img_src
					)
				END,
				char(10)
			) FROM grid WHERE category_id = grid_categories.id
		)
	)
FROM grid_categories;

SELECT 'changequote';