SELECT
   CASE
      WHEN tq_month IS NULL AND tq_day_of_month = 1 THEN FORMAT('%02d-ARM', STRFTIME('%Y') - 1969 + year_diff)
      WHEN tq_month IS NULL AND tq_day_of_month = 2 THEN FORMAT('%02d-ALD', STRFTIME('%Y') - 1969 + year_diff)
      WHEN tq_month IS NULL AND tq_day_of_month != 1 AND tq_day_of_month != 2 THEN 'ERROR!'
      ELSE FORMAT('%02d-%s%02d', STRFTIME('%Y') - 1969 + 1 - year_diff, char(unicode('A') + tq_month - 1) ,tq_day_of_month)
   END
FROM gr_tq_lookup
WHERE gr_month = STRFTIME('%m') AND gr_day_of_month = STRFTIME('%d');