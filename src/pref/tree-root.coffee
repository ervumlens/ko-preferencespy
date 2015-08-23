
log = require('ko/logging').getLogger 'preference-spy'

TreeRow = require 'preferencespy/pref/tree-row'
Sorter = require 'preferencespy/pref/sorter'

class TreeRoot extends TreeRow
	allRows: []
	sorter: new Sorter null, -> false

	constructor: ->
		@root = @
		@isRoot = true

	index: ->
		-1

	addChild: (childRow) ->
		super
		@allRows.push childRow

	clearChildren: ->
		super
		@allRows = []

	visibleRowCount: ->
		@allRows.length

	getFilteredRow: (index) ->
		@allRows[index]

	getUnfilteredIndex: (index) ->
		index

	isOpen: ->
		true

	open: ->
	close: ->

	parentIndex: (index) ->
		@getFilteredRow(index).parentIndex()

	insertChildren: (row) ->
		#Insert the children into @allRows
		inserted = row.childCount()
		filteredIndex = row.index()
		trueIndex = @getUnfilteredIndex filteredIndex
		#log.warn "Inserting #{inserted} rows, starting at #{row.index()} (#{trueIndex})"

		newRows = row.children
		for i in [0 ... inserted]
			@allRows.splice trueIndex + 1 + i, 0, newRows[i]

		#Call @treebox.rowCountChanged
		@treebox.rowCountChanged filteredIndex + 1, inserted

	removeChildren: (row, filteredIndex) ->
		#remove the children into @allRows
		removed = row.childCount()
		filteredIndex = row.index()
		trueIndex = @getUnfilteredIndex filteredIndex
		#log.warn "Removing #{removed} rows, starting at #{row.index()} (#{trueIndex})"

		@allRows.splice trueIndex + 1, removed

		#Call @treebox.rowCountChanged
		@treebox.rowCountChanged filteredIndex + 1, -removed

	hasNextSibling: (index) ->
		row = @getFilteredRow index
		row.nextSibling?

	sort: (sorter, col) ->
		direction = null
		if @sorter.id is sorter.id
			@sorter.reverse()
			direction = if @sorter.reversed then 'descending' else 'ascending'
		else
			@sorter = sorter.clone()
			direction = 'ascending'

		@treebox.beginUpdateBatch()
		try
			super @sorter
		catch e
			log.exception "Problem sorting: " + e
		finally
			@updateColumnSortUI col, direction
			@treebox.endUpdateBatch()

	updateColumnSortUI: (col, direction) ->
		tree = document.getElementById 'preferencespy-tree'
		columns = col.columns
		tree.setAttribute 'sortResource', col.id

		#Clear all sort attributes everywhere
		for i in [0 ... columns.length]
			otherCol = columns.getColumnAt(i)
			otherCol.element.removeAttribute 'sortDirection'

		col.element.setAttribute 'sortDirection', direction
		tree.setAttribute 'sortDirection', direction

module.exports = TreeRoot
