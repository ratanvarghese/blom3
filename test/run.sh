if [ -z "$1" ]; then
	echo "Error: no directory provided. Exiting..."
	exit 64
fi

if [ -z "$2" ]; then
	echo "Error: no blom.sh (legacy) site directory provided. Exiting..."
	exit 64
fi

blomdir=$(realpath $1)
legacydir=$(realpath $2)

db="$blomdir/blom.db"
src="$blomdir/src"
test="$blomdir/test"
bin="$blomdir/bin"

dash -ex "$bin/blom-clean" $blomdir

rm -f $db
sqlite3 $db < "$src/init.sql"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/about"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/dumbphone"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/hello"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/cars-three"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/animorphs-font"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/wonder-woman"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/canada-150"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/spiderman-homecoming"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/innocent-controversy"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/goodbye-facebook"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/blog-enhancements"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/adding-comments"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/endgame"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/windows-era"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/lightyear"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/j-corruption"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/j-seventies"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/j-insurance"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/j-smoking"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/j-stutter"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/j-executed"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/j-farmers"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/j-cardboard-0"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/j-mutual-defiance"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/j-candy-cane"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/j-astronomers"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/j-embarassed"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/j-bloom"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/predictions-for-avatar"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/z-bird"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/j-whisky"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/j-fitness"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/j-cardboard-1"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/j-revolution"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/j-misremembered"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/chatgpt"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/j-choices"
dash -ex "$test/migrate.sh" $blomdir "$legacydir/j-autumn"
sqlite3 $db < "$test/insert.sql"

dash -ex "$bin/blom-update" $blomdir