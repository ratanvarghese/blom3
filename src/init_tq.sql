-- The Tranquility Calendar
-- https://www.orionsarm.com/eg-article/48c6d4c3d54cf
-- https://web.archive.org/web/20161025042320/http://www.mithrandir.com/Tranquility/tranquilityArticle.html
-- https://web.archive.org/web/20180818233025/https://en.wikipedia.org/wiki/Tranquility_calendar
-- One odd characteristic of the Tranquility Calendar is that each day of year has a 1-to-1
-- relationship with a Gregorian day of year, even February 29.
-- We can use this characteristic to make a lookup table Gregorian and Tranquility days.

CREATE TABLE tq_months(
   id INTEGER NOT NULL PRIMARY KEY,
   name TEXT NOT NULL UNIQUE
) STRICT;

CREATE TABLE tq_intercalary(
   id INTEGER NOT NULL PRIMARY KEY,
   name TEXT NOT NULL UNIQUE
) STRICT;

CREATE TABLE tq_days(
   day_of_month INTEGER NOT NULL PRIMARY KEY
) STRICT;

CREATE TABLE gr_tq_cutoff(
   tq_month INTEGER NOT NULL PRIMARY KEY,
   cutoff_tq_day INTEGER NOT NULL,
   start_year_diff INTEGER NOT NULL,
   start_gr_month INTEGER NOT NULL,
   start_gr_day INTEGER NOT NULL,
   end_gr_month INTEGER NOT NULL,
   end_gr_day INTEGER NOT NULL,
   end_year_diff INTEGER NOT NULL
) STRICT;

CREATE TABLE gr_tq_lookup(
   gr_day_of_month INTEGER NOT NULL,
   gr_month INTEGER NOT NULL,
   year_diff INTEGER NOT NULL,
   tq_day_of_month INTEGER NOT NULL,
   tq_month INTEGER,
   UNIQUE(gr_day_of_month, gr_month),
   UNIQUE(tq_day_of_month, tq_month)
) STRICT;

INSERT INTO tq_months (id, name) VALUES
(1, 'Archimedes'),
(2, 'Brahe'),
(3, 'Copernicus'),
(4, 'Darwin'),
(5, 'Einstein'),
(6, 'Faraday'),
(7, 'Galileo'),
(8, 'Hippocrates'),
(9, 'Imhotep'),
(10, 'Jung'),
(11, 'Kepler'),
(12, 'Lavoisier'),
(13, 'Mendel')
;

INSERT INTO tq_intercalary (id, name) VALUES
(1, 'Armstrong Day'),
(2, 'Aldrin Day')
;

INSERT INTO tq_days (day_of_month) VALUES
(1),  (2),  (3),  (4),  (5),  (6),  (7),
(8),  (9),  (10), (11), (12), (13), (14),
(15), (16), (17), (18), (19), (20), (21),
(22), (23), (24), (25), (26), (27), (28);

INSERT INTO gr_tq_cutoff (
   tq_month,
   cutoff_tq_day,
   start_year_diff,
   start_gr_month,
   start_gr_day,
   end_year_diff,
   end_gr_month,
   end_gr_day
) VALUES
   (01, 12, 0, 07, 21, 0, 08, 17),
   (02, 15, 0, 08, 18, 0, 09, 14),
   (03, 17, 0, 09, 15, 0, 10, 12),
   (04, 20, 0, 10, 13, 0, 11, 09),
   (05, 22, 0, 11, 10, 0, 12, 07),
   (06, 25, 0, 12, 08, 1, 01, 04),
   (07, 28, 1, 01, 05, 1, 02, 01),
   (08, 28, 1, 02, 02, 1, 03, 01),
   (09, 29, 1, 03, 02, 1, 03, 29),
   (10, 03, 1, 03, 30, 1, 04, 26),
   (11, 05, 1, 04, 27, 1, 05, 24),
   (12, 08, 1, 05, 25, 1, 06, 21),
   (13, 10, 1, 06, 22, 1, 07, 19)
;

-- Special days
INSERT INTO gr_tq_lookup (gr_day_of_month, gr_month, year_diff, tq_day_of_month)
VALUES
   (20, 7, 0, 1),
   (29, 2, 1, 2)
;

-- Normal Days
INSERT INTO gr_tq_lookup (gr_day_of_month, gr_month, year_diff, tq_day_of_month, tq_month)
SELECT
   CASE
      WHEN day_of_month < cutoff_tq_day THEN day_of_month + start_gr_day - 1
      ELSE day_of_month + end_gr_day - 28
   END AS gr_day_of_month,
   CASE
      WHEN day_of_month < cutoff_tq_day THEN start_gr_month
      ELSE end_gr_month
   END AS gr_month,
   CASE
      WHEN day_of_month < cutoff_tq_day THEN start_year_diff
      ELSE end_year_diff
   END AS year_diff,
   day_of_month,
   tq_month
FROM tq_days, gr_tq_cutoff;
