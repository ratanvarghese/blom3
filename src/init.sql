PRAGMA encoding = 'UTF-8';
CREATE TABLE tags(
	id INTEGER NOT NULL PRIMARY KEY,
	name TEXT NOT NULL UNIQUE,
	CHECK(name = TRIM(LOWER(name))) 
) STRICT;
CREATE TABLE articles(
	id INTEGER NOT NULL PRIMARY KEY,
	url TEXT NOT NULL UNIQUE,
	title TEXT NOT NULL,
	date_modified TEXT NOT NULL,
	date_published TEXT NOT NULL,
	content_md TEXT NOT NULL,
	class TEXT,
	CHECK(url = TRIM(LOWER(url))),
	CHECK(title = TRIM(title)),
	CHECK(date_modified = STRFTIME("%Y-%m-%dT%H:%M:%f", date_modified)),
	CHECK(date_published = STRFTIME("%Y-%m-%dT%H:%M:%f", date_published)),
	CHECK(UNIXEPOCH(date_published) <= UNIXEPOCH(date_modified))
) STRICT;
CREATE TABLE attachments(
	file_name TEXT NOT NULL,
	mime_type TEXT NOT NULL,
	article_id INTEGER NOT NULL,
	FOREIGN KEY(article_id) REFERENCES articles(id),
	CHECK(mime_type LIKE "%/%")
) STRICT;
CREATE TABLE article_tags(
	article_id INTEGER NOT NULL,
	tag_id INTEGER NOT NULL,
	FOREIGN KEY(article_id) REFERENCES articles(id)
	FOREIGN KEY(tag_id) REFERENCES tags(id)
) STRICT;
CREATE TABLE grid_categories(
	id INTEGER NOT NULL PRIMARY KEY,
	class TEXT,
	name TEXT NOT NULL,
	CHECK(name = TRIM(name))
) STRICT;
CREATE TABLE grid(
	id INTEGER NOT NULL PRIMARY KEY,
	category_id INTEGER NOT NULL,
	href TEXT,
	img_src TEXT,
	label TEXT,
	FOREIGN KEY(category_id) REFERENCES grid_categories(id)
) STRICT;