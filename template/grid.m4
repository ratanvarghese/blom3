divert(-1)
define(`_GRID_COLUMN_START', `<div class="creative-column">')
define(`_GRID_START', `<div class="creative-box-grid">')
define(`_GRID_END', `</div>')
define(`_GRID_COLUMN_END', `</div>')
define(`_GRID_NAME', `<h2>$1</h2>')
define(`_GRID_BOX',`
	ifelse($#, 3,
	<a class="creative-box $1" href="$2">
		<img src="$3" />
	</a>,
	<a class="creative-box $1" href="$2">
		<img src="$3" />
		<label>$4</label>
	</a>)
')
divert(0)dnl
