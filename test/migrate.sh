if [ -z "$1" ]; then
	echo "Error: no blom3 directory provided. Exiting..."
	exit 64
fi

if [ -z "$2" ]; then
	echo "Error: no blom.sh (legacy) article directory provided. Exiting..."
	exit 64
fi

blomdir=$(realpath $1)
legacydir=$(realpath $2)

db="$blomdir/blom.db"
bin="$blomdir/bin"
public="$blomdir/public"

content="$legacydir/content.md"
item="$legacydir/item.json"

url=$(basename $legacydir)
title=$(jq -r .title < $item)
tags=$(jq -r '.tags[]' < $item | sed 's/ /-/g' | sed 's/^/-g /g')
published=$(date -d $(jq -r .date_published < $item) '+%s')
raw_class=$(jq -r ._ratan_blog_class < $item)
if [ -n "$raw_class" ]; then
	class="-c $raw_class"
fi

rm -rf "$public/$url"
mkdir "$public/$url"
if [ -d "$legacydir/attachments" ]; then
	cp -R "$legacydir/attachments" "$public/$url/attachments"
fi

$bin/blom-article -d "$db" -u "$url" -m "$content" -t "$title" \
                  -p "$published" $class $tags